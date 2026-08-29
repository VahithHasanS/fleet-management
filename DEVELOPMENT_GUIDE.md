# Complete Development Guide - Step by Step

> **Current repository implementation note (2026-08-28):** The runnable project uses
> `backend/` (NestJS + MongoDB + Redis), `admin/` (Flutter Web), and `driver/`
> (Flutter Web/Android). The driver operations API persists HOS, DVIR, and wellness
> check-ins at `/api/v1/tenants/:tenantId/driver-operations`; use `README.md` and
> `context.md` for current commands and module status.

## From Scratch to Deployment

---

## Phase 0: Pre-Development (Day 1-2)

### Step 1: Setup Your Development Environment

**Install Required Software:**

| Software | Purpose | Download |
|----------|---------|----------|
| **Node.js** (v18+) | JavaScript runtime | nodejs.org |
| **VS Code** | Code editor | code.visualstudio.com |
| **Git** | Version control | git-scm.com |
| **Docker** (optional) | Containerization | docker.com |
| **PostgreSQL** (v15+) | Database | postgresql.org |

**Install VS Code Extensions:**
```
- ESLint
- Prettier
- Tailwind CSS IntelliSense
- ES7+ React/Redux/React-Native snippets
- GitLens
```

---

### Step 2: Create Project Structure

**Open Terminal and run:**

```bash
# Create project folder
mkdir fleet-safety-system
cd fleet-safety-system

# Initialize Git
git init

# Create monorepo structure
mkdir -p apps/web apps/mobile apps/api apps/shared
```

**Final folder structure:**
```
fleet-safety-system/
├── apps/
│   ├── web/              # React Web Dashboard
│   ├── mobile/           # React Native Mobile App
│   ├── api/              # Node.js Backend API
│   └── shared/           # Shared types/utils
├── docs/                 # Documentation
├── docker-compose.yml
├── package.json
└── README.md
```

---

## Phase 1: Backend API Setup (Day 3-5)

### Step 3: Initialize Backend

```bash
cd apps/api

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express cors helmet morgan dotenv
npm install prisma @prisma/client
npm install jsonwebtoken bcryptjs
npm install express-validator
npm install socket.io
npm install axios

# Install dev dependencies
npm install -D nodemon typescript @types/node @types/express
npm install -D ts-node @types/cors @types/morgan
npm install -D @types/jsonwebtoken @types/bcryptjs
```

---

### Step 4: Setup TypeScript

**Create `tsconfig.json`:**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

---

### Step 5: Create Backend Structure

```bash
# Create folder structure
mkdir -p src/{config,controllers,middleware,models,routes,services,utils,types}

# Create main files
touch src/index.ts
touch src/config/database.ts
touch src/config/env.ts
touch src/middleware/auth.ts
touch src/middleware/errorHandler.ts
touch src/routes/index.ts
touch src/utils/logger.ts
```

---

### Step 6: Create Database Schema (Prisma)

**Install Prisma:**
```bash
npx prisma init
```

**Edit `prisma/schema.prisma`:**
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  password      String
  name          String
  role          Role      @default(DRIVER)
  phone         String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  driver        Driver?
}

enum Role {
  ADMIN
  MANAGER
  DRIVER
}

model Vehicle {
  id            String    @id @default(cuid())
  name          String
  plateNumber   String    @unique
  type          VehicleType
  status        VehicleStatus @default(OFFLINE)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  driver        Driver?
  trips         Trip[]
  maintenance   Maintenance[]
}

enum VehicleType {
  TRUCK
  VAN
  CAR
  BUS
}

enum VehicleStatus {
  ONLINE
  OFFLINE
  IN_TRANSIT
  MAINTENANCE
}

model Driver {
  id            String    @id @default(cuid())
  userId        String    @unique
  user          User      @relation(fields: [userId], references: [id])
  vehicleId     String?   @unique
  vehicle       Vehicle?  @relation(fields: [vehicleId], references: [id])
  licenseNumber String    @unique
  safetyScore   Float     @default(100)
  trips         Trip[]
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

model Trip {
  id            String    @id @default(cuid())
  driverId      String
  driver        Driver    @relation(fields: [driverId], references: [id])
  vehicleId     String
  vehicle       Vehicle   @relation(fields: [vehicleId], references: [id])
  startLocation Json
  endLocation   Json?
  startTime     DateTime  @default(now())
  endTime       DateTime?
  distance      Float?
  status        TripStatus @default(ACTIVE)
  events        SafetyEvent[]
  createdAt     DateTime  @default(now())
}

enum TripStatus {
  ACTIVE
  COMPLETED
  CANCELLED
}

model SafetyEvent {
  id            String    @id @default(cuid())
  tripId        String
  trip          Trip      @relation(fields: [tripId], references: [id])
  type          EventType
  severity      Severity
  location      Json
  timestamp     DateTime  @default(now())
  videoUrl      String?
  description   String?
}

enum EventType {
  HARSH_BRAKING
  RAPID_ACCELERATION
  SHARP_TURN
  SPEEDING
  DROWSINESS
  DISTRACTION
  PHONE_USAGE
  COLLISION
}

enum Severity {
  LOW
  MEDIUM
  HIGH
  CRITICAL
}

model Maintenance {
  id            String    @id @default(cuid())
  vehicleId     String
  vehicle       Vehicle   @relation(fields: [vehicleId], references: [id])
  type          String
  description   String
  status        MaintenanceStatus @default(PENDING)
  scheduledDate DateTime
  completedDate DateTime?
  cost          Float?
  createdAt     DateTime  @default(now())
}

enum MaintenanceStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  CANCELLED
}
```

**Run migration:**
```bash
npx prisma migrate dev --name init
```

---

### Step 7: Create Backend Files

**`src/index.ts`:**
```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { Server } from 'socket.io';
import routes from './routes';
import { errorHandler } from './middleware/errorHandler';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_URL || 'http://localhost:3000',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', routes);

// Error handler
app.use(errorHandler);

// Socket.IO for real-time
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('vehicle-location', (data) => {
    io.emit('location-update', data);
  });
  
  socket.on('safety-alert', (data) => {
    io.emit('alert', data);
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;

httpServer.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export { io };
```

---

**`src/routes/index.ts`:**
```typescript
import { Router } from 'express';
import authRoutes from './auth.routes';
import vehicleRoutes from './vehicle.routes';
import driverRoutes from './driver.routes';
import tripRoutes from './trip.routes';
import safetyRoutes from './safety.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/vehicles', vehicleRoutes);
router.use('/drivers', driverRoutes);
router.use('/trips', tripRoutes);
router.use('/safety', safetyRoutes);

export default router;
```

---

**`src/middleware/auth.ts`:**
```typescript
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  user?: any;
}

export const authenticate = (req: AuthRequest, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

export const authorize = (...roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    next();
  };
};
```

---

## Phase 2: Frontend Web Dashboard (Day 6-12)

### Step 8: Initialize React App

```bash
cd apps/web

# Create React app with TypeScript
npx create-react-app . --template typescript

# Install dependencies
npm install tailwindcss postcss autoprefixer
npm install react-router-dom @tanstack/react-query
npm install axios socket.io-client
npm install recharts react-leaflet leaflet
npm install @headlessui/react @heroicons/react
npm install zustand

# Install dev dependencies
npm install -D @types/leaflet
```

---

### Step 9: Setup Tailwind CSS

```bash
npx tailwindcss init -p
```

**Edit `tailwind.config.js`:**
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        dark: {
          100: '#1e293b',
          200: '#0f172a',
          300: '#020617',
        }
      },
    },
  },
  plugins: [],
}
```

**Edit `src/index.css`:**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  @apply bg-dark-200 text-gray-100;
}
```

---

### Step 10: Create Web App Structure

```bash
# Create folder structure
mkdir -p src/{components/{layout,dashboard,fleet,safety,reports},pages,hooks,services,store,types,utils}

# Create main files
touch src/App.tsx
touch src/routes.tsx
touch src/services/api.ts
touch src/store/useStore.ts
touch src/types/index.ts
```

---

### Step 11: Create Main Layout

**`src/components/layout/Sidebar.tsx`:**
```tsx
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  HomeIcon,
  TruckIcon,
  ShieldCheckIcon,
  ClockIcon,
  ChartBarIcon,
  CogIcon,
} from '@heroicons/react/24/outline';

const menuItems = [
  { name: 'Dashboard', path: '/', icon: HomeIcon },
  { name: 'Fleet', path: '/fleet', icon: TruckIcon },
  { name: 'Safety', path: '/safety', icon: ShieldCheckIcon },
  { name: 'ELD', path: '/eld', icon: ClockIcon },
  { name: 'Reports', path: '/reports', icon: ChartBarIcon },
  { name: 'Settings', path: '/settings', icon: CogIcon },
];

export default function Sidebar() {
  const location = useLocation();

  return (
    <div className="fixed left-0 top-0 h-full w-64 bg-dark-100 border-r border-gray-700">
      <div className="p-6">
        <h1 className="text-2xl font-bold text-primary-500">FleetSafe</h1>
      </div>
      
      <nav className="px-4">
        {menuItems.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className={`flex items-center gap-3 px-4 py-3 mb-2 rounded-lg transition-colors ${
              location.pathname === item.path
                ? 'bg-primary-600 text-white'
                : 'text-gray-400 hover:bg-dark-100 hover:text-white'
            }`}
          >
            <item.icon className="w-5 h-5" />
            <span>{item.name}</span>
          </Link>
        ))}
      </nav>
    </div>
  );
}
```

---

### Step 12: Create Dashboard Page

**`src/pages/Dashboard.tsx`:**
```tsx
import React from 'react';
import { TruckIcon, ShieldCheckIcon, ExclamationTriangleIcon, ClockIcon } from '@heroicons/react/24/outline';

const kpiCards = [
  { title: 'Active Vehicles', value: '125', icon: TruckIcon, change: '+5', color: 'bg-green-500' },
  { title: 'Safety Score', value: '87%', icon: ShieldCheckIcon, change: '+2%', color: 'bg-blue-500' },
  { title: 'Active Alerts', value: '12', icon: ExclamationTriangleIcon, change: '-3', color: 'bg-yellow-500' },
  { title: 'Compliance', value: '98.5%', icon: ClockIcon, change: '+0.5%', color: 'bg-purple-500' },
];

export default function Dashboard() {
  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Dashboard</h1>
      
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {kpiCards.map((card, index) => (
          <div key={index} className="bg-dark-100 rounded-xl p-6 border border-gray-700">
            <div className="flex items-center justify-between mb-4">
              <div className={`p-3 rounded-lg ${card.color}`}>
                <card.icon className="w-6 h-6 text-white" />
              </div>
              <span className="text-green-400 text-sm">{card.change}</span>
            </div>
            <h3 className="text-gray-400 text-sm">{card.title}</h3>
            <p className="text-3xl font-bold mt-1">{card.value}</p>
          </div>
        ))}
      </div>
      
      {/* Map and Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-dark-100 rounded-xl p-6 border border-gray-700">
          <h2 className="text-xl font-bold mb-4">Fleet Map</h2>
          <div className="h-96 bg-dark-200 rounded-lg flex items-center justify-center">
            <p className="text-gray-500">Map Integration Here</p>
          </div>
        </div>
        
        <div className="bg-dark-100 rounded-xl p-6 border border-gray-700">
          <h2 className="text-xl font-bold mb-4">Recent Alerts</h2>
          <div className="space-y-4">
            {/* Alert items */}
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## Phase 3: Mobile App Setup (Day 13-18)

### Step 13: Initialize React Native App

```bash
cd apps/mobile

# Create React Native app
npx react-native init FleetSafeMobile --template react-native-template-typescript

# Navigate to project
cd FleetSafeMobile

# Install dependencies
npm install @react-navigation/native @react-navigation/bottom-tabs
npm install @react-navigation/native-stack
npm install react-native-screens react-native-safe-area-context
npm install axios socket.io-client
npm install @tanstack/react-query
npm install react-native-maps
npm install react-native-vector-icons
npm install zustand
```

---

### Step 14: Create Mobile App Structure

```bash
# Create folder structure
mkdir -p src/{screens,components,navigation,services,store,types,utils}

# Create main files
touch src/App.tsx
touch src/navigation/MainNavigator.tsx
touch src/services/api.ts
touch src/store/useStore.ts
```

---

### Step 15: Create Driver ELD Screen

**`src/screens/ELDScreen.tsx`:**
```tsx
import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

type DutyStatus = 'DRIVE' | 'ON_DUTY' | 'OFF_DUTY' | 'SLEEPER';

export default function ELDScreen() {
  const [dutyStatus, setDutyStatus] = useState<DutyStatus>('OFF_DUTY');
  const [drivingTime, setDrivingTime] = useState(8 * 60 + 45); // 8:45 in minutes
  const [onDutyTime, setOnDutyTime] = useState(12 * 60 + 30); // 12:30 in minutes

  const formatTime = (minutes: number) => {
    const hrs = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hrs}:${mins.toString().padStart(2, '0')}`;
  };

  const statusColors: Record<DutyStatus, string> = {
    DRIVE: '#22C55E',
    ON_DUTY: '#EAB308',
    OFF_DUTY: '#6B7280',
    SLEEPER: '#3B82F6',
  };

  return (
    <View style={styles.container}>
      {/* Status Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Hours of Service</Text>
        <Text style={styles.subtitle}>Current Status: {dutyStatus}</Text>
      </View>

      {/* Duty Status Buttons */}
      <View style={styles.statusGrid}>
        {(['DRIVE', 'ON_DUTY', 'OFF_DUTY', 'SLEEPER'] as DutyStatus[]).map((status) => (
          <TouchableOpacity
            key={status}
            style={[
              styles.statusButton,
              { backgroundColor: dutyStatus === status ? statusColors[status] : '#1E293B' },
            ]}
            onPress={() => setDutyStatus(status)}
          >
            <Text style={[styles.statusText, { color: dutyStatus === status ? '#FFF' : '#94A3B8' }]}>
              {status.replace('_', ' ')}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* HOS Clocks */}
      <View style={styles.clocksContainer}>
        <View style={styles.clock}>
          <Text style={styles.clockLabel}>Driving</Text>
          <Text style={[styles.clockValue, { color: drivingTime < 60 ? '#EF4444' : '#22C55E' }]}>
            {formatTime(drivingTime)}
          </Text>
          <Text style={styles.clockLimit}>/ 11:00</Text>
        </View>

        <View style={styles.clock}>
          <Text style={styles.clockLabel}>On Duty</Text>
          <Text style={[styles.clockValue, { color: onDutyTime < 120 ? '#EF4444' : '#22C55E' }]}>
            {formatTime(onDutyTime)}
          </Text>
          <Text style={styles.clockLimit}>/ 14:00</Text>
        </View>

        <View style={styles.clock}>
          <Text style={styles.clockLabel}>Break</Text>
          <Text style={styles.clockValue}>0:00</Text>
          <Text style={styles.clockLimit}>Required</Text>
        </View>
      </View>

      {/* Graph Grid (24-hour timeline) */}
      <View style={styles.graphContainer}>
        <Text style={styles.graphTitle}>24-Hour Timeline</Text>
        <View style={styles.graph}>
          {/* Graph bars would go here */}
          <View style={[styles.graphBar, { left: '0%', width: '35%', backgroundColor: '#6B7280' }]} />
          <View style={[styles.graphBar, { left: '35%', width: '25%', backgroundColor: '#22C55E' }]} />
          <View style={[styles.graphBar, { left: '60%', width: '15%', backgroundColor: '#EAB308' }]} />
          <View style={[styles.graphBar, { left: '75%', width: '25%', backgroundColor: '#3B82F6' }]} />
        </View>
      </View>

      {/* Certify Button */}
      <TouchableOpacity style={styles.certifyButton}>
        <Text style={styles.certifyButtonText}>Certify Logs</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
    padding: 20,
  },
  header: {
    marginBottom: 30,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#F8FAFC',
  },
  subtitle: {
    fontSize: 16,
    color: '#94A3B8',
    marginTop: 5,
  },
  statusGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginBottom: 30,
  },
  statusButton: {
    flex: 1,
    minWidth: '45%',
    padding: 15,
    borderRadius: 12,
    alignItems: 'center',
  },
  statusText: {
    fontWeight: '600',
    fontSize: 14,
  },
  clocksContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 30,
  },
  clock: {
    alignItems: 'center',
    backgroundColor: '#1E293B',
    padding: 20,
    borderRadius: 12,
    flex: 1,
    marginHorizontal: 5,
  },
  clockLabel: {
    color: '#94A3B8',
    fontSize: 12,
    marginBottom: 5,
  },
  clockValue: {
    fontSize: 28,
    fontWeight: 'bold',
  },
  clockLimit: {
    color: '#64748B',
    fontSize: 12,
    marginTop: 5,
  },
  graphContainer: {
    backgroundColor: '#1E293B',
    padding: 20,
    borderRadius: 12,
    marginBottom: 30,
  },
  graphTitle: {
    color: '#F8FAFC',
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 15,
  },
  graph: {
    height: 60,
    position: 'relative',
  },
  graphBar: {
    position: 'absolute',
    height: 40,
    top: 10,
    borderRadius: 4,
  },
  certifyButton: {
    backgroundColor: '#2563EB',
    padding: 18,
    borderRadius: 12,
    alignItems: 'center',
  },
  certifyButtonText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '600',
  },
});
```

---

## Phase 4: Real-time Features (Day 19-22)

### Step 16: Setup Socket.IO

**`src/services/socket.ts` (Backend):**
```typescript
import { Server } from 'socket.io';

export const setupSocket = (io: Server) => {
  // Vehicle location tracking
  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    // Join vehicle room
    socket.on('join-vehicle', (vehicleId) => {
      socket.join(`vehicle:${vehicleId}`);
    });

    // Broadcast vehicle location
    socket.on('update-location', (data) => {
      io.emit('location-update', data);
    });

    // Safety alerts
    socket.on('safety-alert', (data) => {
      io.emit('alert', data);
    });

    // Driver status updates
    socket.on('driver-status', (data) => {
      io.emit('status-update', data);
    });

    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
    });
  });
};
```

---

### Step 17: Real-time Map Component

**`src/components/fleet/LiveMap.tsx`:**
```tsx
import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import { io } from 'socket.io-client';
import 'leaflet/dist/leaflet.css';

interface VehicleLocation {
  id: string;
  lat: number;
  lng: number;
  speed: number;
  status: string;
  driverName: string;
}

export default function LiveMap() {
  const [vehicles, setVehicles] = useState<VehicleLocation[]>([]);

  useEffect(() => {
    const socket = io(process.env.REACT_APP_WS_URL || 'ws://localhost:5000');

    socket.on('location-update', (data: VehicleLocation) => {
      setVehicles((prev) => {
        const index = prev.findIndex((v) => v.id === data.id);
        if (index >= 0) {
          const updated = [...prev];
          updated[index] = data;
          return updated;
        }
        return [...prev, data];
      });
    });

    return () => {
      socket.disconnect();
    };
  }, []);

  return (
    <MapContainer
      center={[39.8283, -98.5795]}
      zoom={4}
      style={{ height: '100%', width: '100%' }}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; OpenStreetMap contributors'
      />
      {vehicles.map((vehicle) => (
        <Marker key={vehicle.id} position={[vehicle.lat, vehicle.lng]}>
          <Popup>
            <div>
              <h3>{vehicle.driverName}</h3>
              <p>Speed: {vehicle.speed} mph</p>
              <p>Status: {vehicle.status}</p>
            </div>
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}
```

---

## Phase 5: AI Integration (Day 23-28)

### Step 18: AI Video Analytics Setup

**`src/services/ai/videoAnalytics.ts`:**
```typescript
import * as tf from '@tensorflow/tfjs';

export class VideoAnalytics {
  private model: tf.LayersModel | null = null;

  async loadModel() {
    // Load pre-trained model for drowsiness detection
    this.model = await tf.loadLayersModel('/models/drowsiness-detector/model.json');
  }

  async detectDrowsiness(videoFrame: HTMLVideoElement) {
    if (!this.model) await this.loadModel();

    const tensor = tf.browser.fromPixels(videoFrame)
      .resizeBilinear([224, 224])
      .expandDims(0)
      .div(255.0);

    const prediction = this.model!.predict(tensor) as tf.Tensor;
    const score = (await prediction.data())[0];

    tensor.dispose();
    prediction.dispose();

    return {
      isDrowsy: score > 0.7,
      confidence: score,
      timestamp: new Date().toISOString(),
    };
  }

  async detectDistraction(videoFrame: HTMLVideoElement) {
    // Similar implementation for distraction detection
    return {
      isDistracted: false,
      gazeDirection: 'forward',
      confidence: 0.95,
    };
  }

  async detectPhoneUsage(videoFrame: HTMLVideoElement) {
    // Phone usage detection
    return {
      phoneDetected: false,
      confidence: 0.92,
    };
  }
}

export const videoAnalytics = new VideoAnalytics();
```

---

### Step 19: Predictive Maintenance Model

**`src/services/ai/predictiveMaintenance.ts`:**
```typescript
export class PredictiveMaintenance {
  async predictMaintenanceNeed(vehicleData: any) {
    // Analyze vehicle data
    const features = {
      mileage: vehicleData.mileage,
      engineHours: vehicleData.engineHours,
      oilPressure: vehicleData.oilPressure,
      coolantTemp: vehicleData.coolantTemp,
      batteryVoltage: vehicleData.batteryVoltage,
      tirePressure: vehicleData.tirePressure,
    };

    // Simple prediction logic (replace with ML model)
    const riskScore = this.calculateRiskScore(features);
    const estimatedDays = this.estimateDaysUntilMaintenance(features);

    return {
      riskScore,
      estimatedDaysUntilMaintenance: estimatedDays,
      recommendedAction: this.getRecommendation(riskScore),
      confidence: 0.85,
    };
  }

  private calculateRiskScore(features: any): number {
    let score = 0;
    
    if (features.oilPressure < 25) score += 30;
    if (features.coolantTemp > 220) score += 25;
    if (features.batteryVoltage < 12.4) score += 20;
    if (features.tirePressure < 30) score += 15;
    if (features.mileage > 50000) score += 10;
    
    return Math.min(score, 100);
  }

  private estimateDaysUntilMaintenance(features: any): number {
    const riskScore = this.calculateRiskScore(features);
    
    if (riskScore > 80) return 7;
    if (riskScore > 60) return 14;
    if (riskScore > 40) return 30;
    return 60;
  }

  private getRecommendation(riskScore: number): string {
    if (riskScore > 80) return 'Urgent maintenance required';
    if (riskScore > 60) return 'Schedule maintenance soon';
    if (riskScore > 40) return 'Monitor closely';
    return 'No immediate action needed';
  }
}

export const predictiveMaintenance = new PredictiveMaintenance();
```

---

## Phase 6: Testing (Day 29-32)

### Step 20: Write Tests

**Backend Tests (Jest):**
```bash
npm install -D jest @types/jest ts-jest
```

**`tests/auth.test.ts`:**
```typescript
import request from 'supertest';
import app from '../src/index';

describe('Auth Endpoints', () => {
  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      });
    expect(res.status).toBe(201);
  });

  it('should login user', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'password123',
      });
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
  });
});
```

---

**Frontend Tests (React Testing Library):**
```bash
npm install -D @testing-library/react @testing-library/jest-dom
```

**`tests/Dashboard.test.tsx`:**
```tsx
import { render, screen } from '@testing-library/react';
import Dashboard from '../pages/Dashboard';

test('renders dashboard title', () => {
  render(<Dashboard />);
  expect(screen.getByText('Dashboard')).toBeInTheDocument();
});

test('displays KPI cards', () => {
  render(<Dashboard />);
  expect(screen.getByText('Active Vehicles')).toBeInTheDocument();
  expect(screen.getByText('Safety Score')).toBeInTheDocument();
});
```

---

## Phase 7: Deployment (Day 33-35)

### Step 21: Docker Setup

**`docker-compose.yml`:**
```yaml
version: '3.8'

services:
  api:
    build: ./apps/api
    ports:
      - '5000:5000'
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/fleetsafe
      - JWT_SECRET=your-secret-key
    depends_on:
      - db

  web:
    build: ./apps/web
    ports:
      - '3000:3000'
    environment:
      - REACT_APP_API_URL=http://api:5000

  db:
    image: postgres:15
    ports:
      - '5432:5432'
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=fleetsafe
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'

volumes:
  postgres_data:
```

---

### Step 22: Deploy to Cloud

**AWS Deployment Options:**

| Service | Purpose | Cost |
|---------|---------|------|
| **EC2** | Backend server | $5-50/month |
| **RDS** | PostgreSQL database | $15-100/month |
| **S3** | File storage | $5-20/month |
| **CloudFront** | CDN | $10-50/month |

**Or use Render/Vercel for easier deployment:**

```bash
# Deploy API to Render
# Deploy Web to Vercel
# Deploy Mobile to App Store/Play Store
```

---

## Development Timeline Summary

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 0** | Day 1-2 | Environment setup, project structure |
| **Phase 1** | Day 3-5 | Backend API, database schema |
| **Phase 2** | Day 6-12 | React web dashboard |
| **Phase 3** | Day 13-18 | React Native mobile app |
| **Phase 4** | Day 19-22 | Real-time features (Socket.IO) |
| **Phase 5** | Day 23-28 | AI integration |
| **Phase 6** | Day 29-32 | Testing |
| **Phase 7** | Day 33-35 | Deployment |

**Total: 35 days (5 weeks)**

---

## Quick Commands Reference

```bash
# Start backend
cd apps/api && npm run dev

# Start frontend
cd apps/web && npm start

# Start mobile
cd apps/mobile && npx react-native run-android

# Run database migrations
npx prisma migrate dev

# Run tests
npm test

# Build for production
npm run build

# Docker commands
docker-compose up -d
docker-compose down
```

---

**Document Version**: 1.0
**Last Updated**: August 2026
**Classification**: Hackathon Competition - Development Guide
**Prepared For**: Development Team
