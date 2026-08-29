import {
  OnGatewayConnection,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { PubSub } from '../common/pubsub';
import { AuthUser, Batch } from '../common/types';
import { TelemetryService } from './telemetry.service';
import { VideoTelematicsService } from '../video-telematics/video-telematics.service';

interface VideoFrameMessage {
  vehicleId?: string;
  tripId?: string;
  ts?: number;
  jpg?: string;
}

interface VideoBreachMessage {
  vehicleId?: string;
  tripId?: string;
  breachType?: string;
  severity?: string;
  durationMs?: number;
  confidence?: number;
  ear?: number;
  snapshot?: string;
  detail?: string;
}

@WebSocketGateway({
  path: '/ws',
  cors: { origin: '*' },
})
export class TelemetryGateway implements OnGatewayInit, OnGatewayConnection {
  @WebSocketServer()
  private server: Server;

  private readonly logger = new Logger(TelemetryGateway.name);

  constructor(
    private readonly pubsub: PubSub,
    private readonly jwt: JwtService,
    private readonly telemetry: TelemetryService,
    private readonly video: VideoTelematicsService,
  ) {}

  afterInit(): void {
    const to = (room: string, event: string, payload: unknown) =>
      this.server.to(room).emit(event, payload);

    this.pubsub.on('live.position', (e) => to(`live:${e.tenantId}`, 'live:position', e.snapshot));
    this.pubsub.on('live.event', (e) => to(`live:${e.tenantId}`, 'live:event', e.event));
    this.pubsub.on('live.alert', (e) => to(`live:${e.tenantId}`, 'live:alert', e.alert));
    this.pubsub.on('live.sos', (e) => to(`live:${e.tenantId}`, 'live:sos', e.panic));
    this.pubsub.on('live.video_breach', (e) =>
      to(`live:${e.tenantId}`, 'live:video_breach', e.breach),
    );
    // Camera frames relay only to the per-tenant video room (admins that ran
    // `video:subscribe`), never to the whole live room.
    this.pubsub.on('video.frame', (e) => to(`video:${e.tenantId}`, 'video:frame', e.frame));
    this.pubsub.on('live.trip', (e) => to(`live:${e.tenantId}`, 'live:trip', e.trip));
    this.pubsub.on('live.leaderboard', (e) =>
      to(`live:${e.tenantId}`, 'live:leaderboard', e.leaderboard),
    );
    this.pubsub.on('simulator.status', (e) =>
      to(`live:${e.tenantId}`, 'simulator:status', e.status),
    );
  }

  async handleConnection(client: Socket): Promise<void> {
    const token =
      (client.handshake.auth?.token as string | undefined) ??
      (client.handshake.query?.token as string | undefined);
    if (!token) {
      client.disconnect(true);
      return;
    }
    try {
      const payload = await this.jwt.verifyAsync(token);
      client.data.user = payload.user as AuthUser;
    } catch {
      client.disconnect(true);
    }
  }

  @SubscribeMessage('telemetry')
  async onTelemetry(
    @ConnectedSocket() client: Socket,
    @MessageBody() batch: Batch,
  ): Promise<{ status: string; reason?: string }> {
    const user = client.data.user as AuthUser | undefined;
    if (!user) return { status: 'rejected', reason: 'unauthenticated' };
    if (!batch || typeof batch !== 'object') return { status: 'rejected', reason: 'malformed' };
    // Gate: drivers stream their assigned vehicle or a simulator daemon streams any.
    if (user.role === 'DRIVER' && user.tenantId) {
      const svc = this.telemetry;
      if (!user.driverId) return { status: 'rejected', reason: 'driver_not_linked' };
      const res = await svc.handleBatch(batch, user.tenantId, user.driverId);
      return { status: res.status, reason: res.reason };
    }
    const res = await this.telemetry.handleBatch(batch, user.tenantId);
    return { status: res.status, reason: res.reason };
  }

  @SubscribeMessage('live:subscribe')
  async onSubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { tenantId?: string },
  ): Promise<{ status: string; tenantId?: string }> {
    const user = client.data.user as AuthUser | undefined;
    if (!user) return { status: 'rejected' };
    const tenantId = user.role === 'SUPER_ADMIN' ? body?.tenantId : user.tenantId;
    if (!tenantId) return { status: 'rejected' };
    await client.join(`live:${tenantId}`);
    return { status: 'ok', tenantId };
  }

  /** Admin/opt-in: receive the per-tenant driver camera frame stream. */
  @SubscribeMessage('video:subscribe')
  async onVideoSubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { tenantId?: string },
  ): Promise<{ status: string; reason?: string; tenantId?: string }> {
    const user = client.data.user as AuthUser | undefined;
    if (!user) return { status: 'rejected' };
    if (user.role === 'DRIVER') return { status: 'rejected', reason: 'drivers_cannot_view_feeds' };
    const tenantId = user.role === 'SUPER_ADMIN' ? body?.tenantId : user.tenantId;
    if (!tenantId) return { status: 'rejected' };
    await client.join(`video:${tenantId}`);
    return { status: 'ok', tenantId };
  }

  /** Driver app: stream a cabin-camera frame (base64 JPEG) for live monitoring. */
  @SubscribeMessage('video:frame')
  onVideoFrame(
    @ConnectedSocket() client: Socket,
    @MessageBody() msg: VideoFrameMessage,
  ): { status: string; reason?: string } {
    const user = client.data.user as AuthUser | undefined;
    if (!user) return { status: 'rejected', reason: 'unauthenticated' };
    if (user.role !== 'DRIVER' || !user.tenantId || !user.driverId) {
      return { status: 'rejected', reason: 'driver_only' };
    }
    if (!msg?.vehicleId || typeof msg.jpg !== 'string' || msg.jpg.length < 64) {
      return { status: 'rejected', reason: 'malformed' };
    }
    // Cap the relayed payload (~150 KB JPEG at 640x480 is plenty for monitoring).
    if (msg.jpg.length > 220_000) return { status: 'rejected', reason: 'too_large' };
    this.pubsub.emit('video.frame', {
      tenantId: user.tenantId,
      frame: {
        vehicleId: msg.vehicleId,
        driverId: user.driverId,
        driverName: user.name,
        tripId: msg.tripId,
        ts: msg.ts ?? Date.now(),
        jpg: msg.jpg,
      },
    });
    return { status: 'ok' };
  }

  /** Driver app: a detected camera breach (drowsiness / eye closure / distraction). */
  async onVideoBreach(
    @ConnectedSocket() client: Socket,
    @MessageBody() msg: VideoBreachMessage,
  ): Promise<{ status: string; reason?: string; id?: string }> {
    const user = client.data.user as AuthUser | undefined;
    if (!user) return { status: 'rejected', reason: 'unauthenticated' };
    if (user.role !== 'DRIVER' || !user.tenantId) {
      return { status: 'rejected', reason: 'driver_only' };
    }
    if (!msg?.vehicleId || !msg.breachType) return { status: 'rejected', reason: 'malformed' };
    try {
      const record = await this.video.recordBreach({
        tenantId: user.tenantId,
        vehicleId: msg.vehicleId,
        tripId: msg.tripId,
        breachType: msg.breachType,
        severity: msg.severity ?? 'high',
        durationMs: msg.durationMs,
        confidence: msg.confidence,
        ear: msg.ear,
        snapshot: msg.snapshot,
        detail: msg.detail,
      });
      return { status: 'ok', id: record.id };
    } catch {
      return { status: 'rejected', reason: 'persist_failed' };
    }
  }

  handleDisconnect(client: Socket): void {
    // Rooms are cleaned automatically by socket.io.
    void client;
  }
}