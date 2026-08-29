# Application Modules & UI Design Guide

## Intelligent Fleet Management & Driver Safety Monitoring System

---

## Table of Contents

1. [Application Overview](#application-overview)
2. [Complete Module List](#complete-module-list)
3. [Module Details & Functions](#module-details--functions)
4. [UI Design Prompts](#ui-design-prompts)
5. [User Flow Diagrams](#user-flow-diagrams)
6. [Screen-by-Screen Breakdown](#screen-by-screen-breakdown)

---

## Application Overview

### Platform Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      WEB DASHBOARD                              │
│                    (Admin/Manager View)                          │
├─────────────────────────────────────────────────────────────────┤
│  Dashboard │ Fleet │ Safety │ Analytics │ Compliance │ Settings │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                   MOBILE APP (Driver)                           │
├─────────────────────────────────────────────────────────────────┤
│  ELD │ HOS │ DVIR │ Navigation │ Alerts │ Score │ Wellness     │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                 MOBILE APP (Manager)                            │
├─────────────────────────────────────────────────────────────────┤
│  Fleet Map │ Alerts │ Approvals │ Reports │ Communication      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Complete Module List

### Core Modules (12 Total)

| # | Module | Priority | Platform |
|---|--------|----------|----------|
| 1 | **Dashboard & Overview** | Critical | Web + Mobile |
| 2 | **Fleet Tracking** | Critical | Web + Mobile |
| 3 | **Driver Safety** | Critical | Web + Mobile |
| 4 | **Video Telematics** | Critical | Web |
| 5 | **Predictive Analytics** | High | Web |
| 6 | **ELD Compliance** | Critical | Mobile (Driver) |
| 7 | **Hours of Service (HOS)** | Critical | Mobile (Driver) |
| 8 | **Driver Vehicle Inspection (DVIR)** | Critical | Mobile (Driver) |
| 9 | **Route Optimization** | High | Web + Mobile |
| 10 | **Maintenance Management** | High | Web |
| 11 | **Driver Wellness** | High | Web + Mobile |
| 12 | **Reports & Analytics** | High | Web |

---

## Module Details & Functions

### Module 1: Dashboard & Overview

**Purpose:** Central command center for fleet managers

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Real-time Fleet Map | Live view of all vehicles on map | Critical |
| KPI Cards | Key metrics at a glance | Critical |
| Active Alerts | Current safety/operational alerts | Critical |
| Vehicle Status | Online/Offline/In Transit summary | Critical |
| Driver Status | Active/On Break/Off Duty | High |
| Today's Summary | Trips, mileage, fuel, safety score | High |
| Quick Actions | Common tasks shortcuts | Medium |
| Notifications Panel | System and alert notifications | High |

**Key Metrics Displayed:**
- Total vehicles active
- Vehicles in transit
- Active alerts (critical/high/medium)
- Average driver score
- Fuel consumption today
- Safety incidents (today/week/month)
- Compliance status

---

### Module 2: Fleet Tracking

**Purpose:** Real-time vehicle location and status monitoring

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Live Map View | Real-time vehicle positions | Critical |
| Vehicle Selection | Click vehicle for details | Critical |
| Geofencing | Create/edit/delete zones | High |
| History Playback | Review past trips | High |
| Traffic Overlay | Real-time traffic conditions | Medium |
| Cluster View | Group vehicles in zoom levels | Medium |
| Multi-map Layers | Satellite/Street/Terrain | Low |
| Search & Filter | Find vehicles by name/driver | High |

**Vehicle Details Panel:**
- Vehicle name and ID
- Driver name
- Current speed
- Direction heading
- Last update time
- Engine status
- Fuel level
- Battery voltage
- Current address
- Trip information

---

### Module 3: Driver Safety

**Purpose:** Monitor and improve driver safety performance

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Driver Scorecard | Individual safety scores | Critical |
| Behavior Analytics | Speeding, braking, acceleration | Critical |
| Risk Assessment | Predictive risk scoring | High |
| Incident History | Past safety events | High |
| Coaching Tools | Driver improvement programs | High |
| Leaderboards | Team performance rankings | Medium |
| Alert Configuration | Set safety thresholds | High |
| Trend Analysis | Safety metrics over time | High |

**Safety Metrics Tracked:**
- Harsh braking events
- Rapid acceleration
- Sharp turns
- Speeding incidents
- Drowsiness detection
- Distraction detection
- Seatbelt compliance
- Phone usage
- Following distance
- Cornering behavior

---

### Module 4: Video Telematics

**Purpose:** AI-powered video monitoring and incident review

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Live Video Feed | Real-time camera views | Critical |
| Event Clips | AI-tagged safety events | Critical |
| Video Playback | Review recorded footage | Critical |
| AI Event Detection | Automatic incident flagging | High |
| Driver Coaching | Video-based training | High |
| Export & Share | Download clips for evidence | High |
| Camera Management | Configure camera settings | Medium |
| Storage Management | Video retention policies | Medium |

**AI Detection Capabilities:**
- Drowsiness (eye closure, yawning)
- Distraction (gaze direction, phone)
- Smoking detection
- Seatbelt status
- Following distance
- Lane departure
- Forward collision risk
- Harsh driving events

---

### Module 5: Predictive Analytics

**Purpose:** AI-powered predictions and insights

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Risk Prediction | Accident probability scoring | High |
| Maintenance Prediction | Failure forecasting | High |
| Fuel Optimization | Consumption predictions | Medium |
| Route Risk Assessment | Road safety analysis | Medium |
| Driver Behavior Forecasting | Trend predictions | Medium |
| Capacity Planning | Fleet size optimization | Low |
| Weather Impact Analysis | Weather risk correlation | Medium |
| Custom ML Models | Build custom predictions | Low |

**Prediction Outputs:**
- 30-day accident probability
- Next maintenance date estimate
- Fuel cost forecast
- Route risk score (1-100)
- Driver improvement trajectory
- Fleet capacity needs

---

### Module 6: ELD Compliance

**Purpose:** Electronic Logging Device compliance management

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| ELD Status | Current device status | Critical |
| Log Editing | Correct log entries | Critical |
| Malfunction Alerts | Device issue notifications | Critical |
| Certification | Daily log certification | Critical |
| Fleet Compliance View | Manager compliance dashboard | High |
| Violation Alerts | HOS violation warnings | Critical |
| Audit Trail | Complete activity log | High |
| Device Management | ELD device inventory | Medium |

---

### Module 7: Hours of Service (HOS)

**Purpose:** Track and manage driver duty status

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Duty Status Toggle | Drive/On Duty/Off Duty/SB | Critical |
| HOS Clocks | Available driving time | Critical |
| Break Timer | 30-min break tracking | Critical |
| Violation Alerts | approaching violations | Critical |
| Weekly Limits | 60/70-hour tracking | Critical |
| HOS Forecasting | Available time projections | High |
| Status History | Duty status log | High |
| Team Driving | Co-driver support | Medium |

**HOS Clocks Displayed:**
- Driving: 11-hour limit
- On Duty: 14-hour window
- Break: 30-minute required
- Weekly: 60/70-hour limit
- Reset: 10-hour break status

---

### Module 8: Driver Vehicle Inspection (DVIR)

**Purpose:** Digital vehicle inspection reports

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Pre-trip Inspection | Start-of-shift check | Critical |
| Post-trip Inspection | End-of-shift check | Critical |
| Defect Reporting | Document issues | Critical |
| Repair Tracking | Work order status | Critical |
| Inspection History | Past inspection records | High |
| Photo Capture | Visual documentation | High |
| Compliance Reports | Inspection statistics | High |
| Template Management | Custom inspection forms | Medium |

**Inspection Categories:**
- Brakes
- Tires
- Lights
- Mirrors
- Fluids
- Steering
- Horn
- Wipers
- Safety equipment
- Cargo security

---

### Module 9: Route Optimization

**Purpose:** AI-powered route planning and optimization

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Route Planning | Create optimal routes | High |
| Multi-stop Optimization | Sequence stops efficiently | High |
| Traffic Integration | Real-time traffic routing | High |
| Weather Routing | Avoid severe weather | Medium |
| Fuel-efficient Routes | Eco-friendly paths | Medium |
| Time Window Management | Delivery scheduling | High |
| Route Comparison | Compare route options | Medium |
| Driver Navigation | Turn-by-turn directions | High |

**Optimization Factors:**
- Distance
- Time
- Fuel consumption
- Traffic conditions
- Road restrictions
- Vehicle capabilities
- Driver preferences
- Customer time windows

---

### Module 10: Maintenance Management

**Purpose:** Preventive and corrective maintenance tracking

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Preventive Scheduling | PM scheduling | High |
| Work Orders | Create/track repairs | High |
| Parts Inventory | Parts management | Medium |
| Maintenance History | Service records | High |
| Cost Tracking | Repair expenses | High |
| Vendor Management | Service provider tracking | Medium |
| Recall Management | OEM recall alerts | Medium |
| Inspection Integration | DVIR to work orders | High |

**Maintenance Types:**
- Oil changes
- Tire rotation/replacement
- Brake service
- Engine diagnostics
- Transmission service
- Battery replacement
- Fluid flushes
- Seasonal maintenance

---

### Module 11: Driver Wellness

**Purpose:** Monitor and improve driver health and wellbeing

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Fatigue Detection | Real-time fatigue monitoring | High |
| Stress Monitoring | Stress level assessment | High |
| Rest Recommendations | Optimal break suggestions | High |
| Wellness Score | Overall driver wellness | High |
| Health Trends | Wellness metrics over time | Medium |
| Fatigue Alerts | Manager notifications | High |
| Wellness Coaching | Improvement programs | Medium |
| Integration | Connect health devices | Low |

**Wellness Metrics:**
- Heart rate (if available)
- Fatigue level (1-10)
- Stress level (1-10)
- Rest quality score
- Driving pattern changes
- Wellness recommendations

---

### Module 12: Reports & Analytics

**Purpose:** Business intelligence and reporting

**Functions:**
| Function | Description | Priority |
|----------|-------------|----------|
| Dashboard Builder | Custom dashboards | High |
| Report Generator | Create custom reports | High |
| Scheduled Reports | Automated delivery | High |
| Data Export | CSV/Excel/PDF export | High |
| KPI Tracking | Custom metric tracking | High |
| Trend Analysis | Historical comparisons | Medium |
| Benchmarking | Industry comparisons | Low |
| API Access | Data integration | Medium |

**Standard Reports:**
- Safety summary
- Driver scorecards
- Fuel consumption
- Maintenance costs
- Compliance status
- Trip history
- Incident reports
- ROI analysis

---

## UI Design Prompts

### Prompt 1: Main Dashboard

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Modern fleet management dashboard UI, dark theme with blue accent colors, 
real-time map showing vehicle locations with green/yellow/red status indicators, 
left sidebar with navigation menu, top KPI cards showing "125 Active Vehicles", 
"98.5% Compliance", "87 Safety Score", "12 Alerts", clean minimalist design, 
professional enterprise software, high contrast, data visualization, 
responsive layout, 4K quality, dribbble style
```

---

### Prompt 2: Fleet Map View

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Fleet tracking map interface, dark mode UI, large map showing 50+ vehicle 
markers with real-time positions, vehicle pop-up card showing driver name, 
speed, status, left panel with vehicle list, search bar and filters at top, 
geofence zones highlighted in semi-transparent blue, traffic overlay, 
modern glassmorphism design, professional logistics software, satellite view option
```

---

### Prompt 3: Driver Scorecard

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Driver safety scorecard dashboard, circular progress showing "87/100" score, 
behavior breakdown cards for "Harsh Braking: 3", "Speeding: 1", "Acceleration: 2", 
timeline graph showing score trend over 30 days, green/yellow/red color coding, 
driver photo and name at top, coaching recommendations section, 
modern card-based UI, clean typography, professional fleet management software
```

---

### Prompt 4: Video Telematics Interface

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Video telematics dashboard, split screen with live camera feed on left, 
event list on right with thumbnails, AI detection boxes highlighting 
drowsiness, distraction, phone usage, event severity indicators (high/medium/low), 
video playback controls, export and share buttons, camera selection dropdown, 
timeline with event markers, dark theme, professional security-style interface
```

---

### Prompt 5: ELD/HOS Mobile App

**Use with:** Midjourney, DELL-E, Figma AI, or similar

```
Mobile ELD app interface, duty status toggle buttons (Drive/On Duty/Off Duty/Sleeper), 
HOS clocks showing "8:45 Driving", "12:30 On Duty", "0:00 Break", 
graph grid showing 24-hour duty status timeline, current status highlighted, 
certify logs button, violation alerts banner, dark mode, truck driver friendly, 
large touch targets, compliant with FMCSA regulations
```

---

### Prompt 6: DVIR Mobile App

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Mobile DVIR inspection app, checklist interface with inspection items, 
checkboxes for each vehicle component (Brakes, Tires, Lights, etc.), 
photo capture button for defects, defect description text field, 
severity selector (Critical/Minor/None), submit inspection button, 
inspection history list, clean simple UI, easy thumb navigation, 
compliance-friendly design, green checkmarks for passed items
```

---

### Prompt 7: Predictive Analytics Dashboard

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Predictive analytics dashboard, risk heat map showing fleet vehicles, 
color-coded risk scores (green=low, red=high), prediction cards showing 
"15% accident probability next 30 days", "Maintenance due in 500 miles", 
line graphs showing trend predictions, AI confidence indicators, 
recommended actions list, modern data visualization, glassmorphism cards, 
professional business intelligence interface
```

---

### Prompt 8: Driver Wellness Interface

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Driver wellness monitoring interface, heart rate graph, fatigue level gauge 
showing "6/10 Moderate", stress level indicator, rest recommendation card 
"Take 20-min break recommended", wellness score circle "78/100", 
weekly trend charts, green/yellow/red status indicators, 
health tips section, calming color palette (blue/green), 
modern health app design, easy to read metrics
```

---

### Prompt 9: Mobile Manager App

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Mobile fleet manager app, bottom navigation (Map, Alerts, Reports, More), 
fleet overview with vehicle count, critical alerts list with notification badges, 
quick approval buttons for DVIR, driver communication section, 
real-time map preview, dark professional theme, thumb-friendly navigation, 
enterprise-grade design, iOS/Android native feel
```

---

### Prompt 10: Reports Dashboard

**Use with:** Midjourney, DALL-E, Figma AI, or similar

```
Reports and analytics dashboard, multiple chart types (bar, line, pie, heatmap), 
KPI cards with trend arrows, date range selector, filter panel, 
export buttons (CSV, PDF, Excel), scheduled reports section, 
custom report builder interface, data tables with sorting/filtering, 
professional business intelligence design, clean typography, 
interactive charts with hover tooltips
```

---

## User Flow Diagrams

### Flow 1: Driver Daily Workflow

```
┌─────────────┐
│ Start Shift  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Log into   │
│  Mobile App │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Start ELD  │
│   Logging   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Pre-trip   │
│  DVIR       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Check HOS  │
│   Status    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Begin      │
│  Driving    │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│  Monitor    │────▶│  Receive    │
│  Safety     │     │  Alerts     │
└──────┬──────┘     └──────┬──────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│  Take       │◀────│  Take Break │
│  Breaks     │     │  (if needed)│
└──────┬──────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│  Complete   │
│  Delivery   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  End Shift  │
│  DVIR       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Certify    │
│  Logs       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Submit    │
│   Logs      │
└─────────────┘
```

---

### Flow 2: Safety Event Workflow

```
┌─────────────────┐
│  Event Detected │
│  (AI System)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Classify       │
│  Severity       │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│ Low   │ │ High  │
│ Alert │ │ Alert │
└───┬───┘ └───┬───┘
    │         │
    ▼         ▼
┌───────┐ ┌───────────┐
│Driver │ │ Manager   │
│Alert  │ │ Alert     │
└───┬───┘ └─────┬─────┘
    │           │
    ▼           ▼
┌───────┐ ┌───────────┐
│Driver │ │ Review    │
│Ack.   │ │ Video     │
└───┬───┘ └─────┬─────┘
    │           │
    ▼           ▼
┌───────┐ ┌───────────┐
│ Log   │ │ Coaching  │
│ Event │ │ Session   │
└───────┘ └───────────┘
```

---

### Flow 3: Predictive Maintenance Workflow

```
┌─────────────────┐
│  Data Collection│
│  (Sensors)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AI Analysis    │
│  (Predictions)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Maintenance    │
│  Predicted      │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│Urgent │ │Scheduled│
│(7 days)│ │(30 days)│
└───┬───┘ └───┬───┘
    │         │
    ▼         ▼
┌───────┐ ┌───────┐
│Work   │ │Schedule│
│Order  │ │Service │
└───┬───┘ └───┬───┘
    │         │
    ▼         ▼
┌───────┐ ┌───────┐
│Repair │ │Complete│
│Done   │ │Work    │
└───┬───┘ └───┬───┘
    │         │
    └────┬────┘
         ▼
┌─────────────────┐
│  Update Vehicle │
│  Records        │
└─────────────────┘
```

---

## Screen-by-Screen Breakdown

### Screen 1: Login Screen

**Elements:**
- Company logo
- Email/username field
- Password field
- Remember me checkbox
- Forgot password link
- Login button
- Background image (fleet/road theme)

**UI Prompt:**
```
Modern login screen for fleet management software, dark theme with 
blue gradient background, company logo placeholder at top, clean 
email and password fields with icons, blue login button, 
"Remember me" checkbox, "Forgot password" link, 
professional enterprise design, minimal and clean
```

---

### Screen 2: Main Dashboard

**Elements:**
- Top bar: Search, notifications, user profile
- Left sidebar: Navigation menu
- Main content:
  - KPI cards row (4 cards)
  - Fleet map (60% width)
  - Alerts panel (40% width)
  - Recent activity feed

**UI Prompt:**
```
Fleet management dashboard, dark mode, top navigation bar with search 
and notifications, left sidebar with menu items (Dashboard, Fleet, 
Safety, ELD, Reports, Settings), main area with 4 KPI cards showing 
vehicles, compliance, safety score, alerts, large map on left with 
vehicle markers, alerts panel on right with recent events, 
clean data visualization, professional enterprise UI
```

---

### Screen 3: Fleet Map View

**Elements:**
- Top bar: Search, date range, view options
- Map: Full screen with vehicle markers
- Left panel: Vehicle list (collapsible)
- Right panel: Vehicle details (on click)
- Bottom: Legend and controls

**UI Prompt:**
```
Fleet tracking interface, full-screen map with vehicle markers in 
different colors (green=active, yellow=idle, red=alert), left panel 
with searchable vehicle list, right panel showing selected vehicle 
details (driver, speed, status, location), geofence zones visible, 
traffic layer toggle, zoom controls, modern dark theme
```

---

### Screen 4: Driver Scorecard

**Elements:**
- Driver info header (photo, name, ID)
- Overall score circle (0-100)
- Behavior breakdown cards
- 30-day trend graph
- Incident history list
- Coaching recommendations

**UI Prompt:**
```
Driver safety scorecard, large circular score indicator showing 87/100, 
driver photo and name at top, grid of behavior cards (harsh braking, 
speeding, acceleration, distraction) each with count and color, 
line graph showing score trend over 30 days, list of recent incidents, 
coaching tips section, clean card-based design, professional fleet UI
```

---

### Screen 5: Video Telematics

**Elements:**
- Camera selector dropdown
- Live video feed area
- Event list sidebar
- Video player controls
- Export/share buttons
- AI detection overlays

**UI Prompt:**
```
Video telematics dashboard, split layout with large video player on 
left showing driver and road view, right sidebar with event list 
showing thumbnails and severity, AI detection boxes on video highlighting 
drowsiness or distraction, playback controls at bottom, camera switcher 
at top, export and share buttons, dark professional interface
```

---

### Screen 6: ELD Mobile App - Main

**Elements:**
- Status bar (time, HOS remaining)
- Duty status toggle buttons
- HOS clocks (3 circles)
- Graph grid (24-hour timeline)
- Bottom navigation
- Certify logs button

**UI Prompt:**
```
Mobile ELD app screen, dark mode, large duty status buttons at top 
(Drive, On Duty, Off Duty, Sleeper) with active state highlighted, 
three circular HOS clocks showing available time, 24-hour graph grid 
showing duty status timeline, "Certify Logs" button at bottom, 
large touch targets, truck driver friendly design, compliant interface
```

---

### Screen 7: DVIR Mobile App

**Elements:**
- Vehicle selector
- Inspection type (Pre/Post)
- Checklist with checkboxes
- Defect reporting section
- Photo capture button
- Submit button

**UI Prompt:**
```
Mobile DVIR inspection app, vehicle selector at top, "Pre-Trip Inspection" 
header, scrollable checklist with items (Brakes, Tires, Lights, Mirrors, 
Fluids) each with checkbox, defect section with text field and severity 
selector, camera icon for photo capture, green "Submit Inspection" button, 
clean simple UI, large touch targets
```

---

### Screen 8: Predictive Analytics

**Elements:**
- Risk heat map
- Prediction cards
- Trend graphs
- AI recommendations
- Confidence indicators

**UI Prompt:**
```
Predictive analytics dashboard, heat map showing fleet vehicles with 
color-coded risk levels, prediction cards showing accident probability 
and maintenance forecasts, line graphs with trend predictions, AI 
recommendation boxes with action items, confidence percentage indicators, 
modern glassmorphism design, professional data visualization
```

---

### Screen 9: Driver Wellness

**Elements:**
- Wellness score display
- Fatigue level gauge
- Stress indicator
- Heart rate graph
- Rest recommendations
- Weekly trends

**UI Prompt:**
```
Driver wellness monitoring interface, circular wellness score showing 
78/100, fatigue gauge with "6/10 Moderate" level, stress indicator bar, 
heart rate line graph, recommendation card suggesting break, weekly trend 
charts, calming blue/green color palette, modern health app design, 
easy-to-read metrics
```

---

### Screen 10: Reports Dashboard

**Elements:**
- Date range picker
- Filter panel
- Multiple chart types
- Data tables
- Export buttons
- Schedule options

**UI Prompt:**
```
Reports analytics dashboard, date range selector at top, filter sidebar 
on left, main area with multiple charts (bar chart for fuel, line chart 
for safety, pie chart for compliance), data table below with sortable 
columns, export buttons (CSV, PDF, Excel), scheduled reports section, 
professional business intelligence design
```

---

## Color Palette & Design System

### Primary Colors

| Color | Hex Code | Usage |
|-------|----------|-------|
| **Primary Blue** | #2563EB | Buttons, links, active states |
| **Dark Blue** | #1E40AF | Headers, emphasis |
| **Light Blue** | #3B82F6 | Hover states, secondary |
| **Background Dark** | #0F172A | Main background |
| **Background Card** | #1E293B | Card backgrounds |
| **Text Primary** | #F8FAFC | Main text |
| **Text Secondary** | #94A3B8 | Subtext, labels |

### Status Colors

| Color | Hex Code | Usage |
|-------|----------|-------|
| **Success Green** | #22C55E | Good status, online |
| **Warning Yellow** | #EAB308 | Caution, alerts |
| **Danger Red** | #EF4444 | Errors, critical |
| **Info Blue** | #3B82F6 | Information |
| **Neutral Gray** | #64748B | Inactive, offline |

---

## Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| **H1** | Inter | 32px | Bold |
| **H2** | Inter | 24px | Semibold |
| **H3** | Inter | 20px | Semibold |
| **Body** | Inter | 16px | Regular |
| **Small** | Inter | 14px | Regular |
| **Caption** | Inter | 12px | Regular |

---

## Component Library

### Buttons

| Type | Style | Usage |
|------|-------|-------|
| **Primary** | Blue filled | Main actions |
| **Secondary** | Blue outline | Secondary actions |
| **Danger** | Red filled | Destructive actions |
| **Ghost** | No fill | Tertiary actions |
| **Icon** | Icon only | Compact actions |

### Cards

| Type | Usage |
|------|-------|
| **KPI Card** | Metric display |
| **List Card** | Item in list |
| **Detail Card** | Expanded info |
| **Action Card** | Interactive card |

### Forms

| Element | Style |
|---------|-------|
| **Input** | Dark background, blue border on focus |
| **Select** | Dropdown with search |
| **Checkbox** | Custom styled, blue when checked |
| **Radio** | Custom styled, blue when selected |
| **Toggle** | Switch with animation |

---

## Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| **Mobile** | < 768px | Single column, bottom nav |
| **Tablet** | 768-1024px | Two columns, collapsible sidebar |
| **Desktop** | > 1024px | Full layout, fixed sidebar |
| **Large Desktop** | > 1440px | Expanded panels |

---

## Quick Reference: All UI Prompts

### Copy-Paste Ready Prompts

**1. Dashboard:**
```
Modern fleet management dashboard UI, dark theme with blue accent colors, 
real-time map showing vehicle locations, KPI cards, left sidebar navigation, 
professional enterprise software, 4K quality
```

**2. Fleet Map:**
```
Fleet tracking map interface, dark mode, vehicle markers with status colors, 
vehicle details panel, search and filters, geofence zones, modern design
```

**3. Driver Scorecard:**
```
Driver safety scorecard, circular score display, behavior breakdown cards, 
trend graph, incident history, coaching recommendations, clean card UI
```

**4. Video Telematics:**
```
Video telematics dashboard, live camera feed, AI detection boxes, event list, 
video controls, export buttons, dark professional interface
```

**5. ELD Mobile:**
```
Mobile ELD app, duty status buttons, HOS clocks, graph grid, certify button, 
dark mode, truck driver friendly, large touch targets
```

**6. DVIR Mobile:**
```
Mobile DVIR app, inspection checklist, defect reporting, photo capture, 
submit button, clean simple UI, compliance-friendly
```

**7. Analytics:**
```
Predictive analytics dashboard, risk heat map, prediction cards, trend graphs, 
AI recommendations, glassmorphism design, data visualization
```

**8. Wellness:**
```
Driver wellness interface, fatigue gauge, stress indicator, heart rate graph, 
rest recommendations, calming blue/green palette, health app design
```

**9. Manager Mobile:**
```
Mobile fleet manager app, bottom navigation, alerts list, fleet overview, 
quick approvals, dark professional theme
```

**10. Reports:**
```
Reports dashboard, multiple charts, data tables, export buttons, 
date filters, professional business intelligence design
```

---

**Document Version**: 1.0
**Last Updated**: August 2026
**Classification**: Hackathon Competition - Application Design
**Prepared For**: UI/UX Design and Development Team
