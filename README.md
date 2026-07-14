# Multi-Echelon Supply Chain Analytics & Inventory Optimization

## 📌 Project Overview
This project delivers an end-to-end analytics and decision-support solution designed to optimize inventory levels across a multi-tiered supply chain network (Factories ➔ Regional Distribution Centers ➔ Local Retail Outlets). 

By aggregating fragmented operational data and applying statistical inventory models, this solution eliminates visibility gaps across tracking streams, minimizes costly stockouts, and reduces capital locked up in excess warehouse dead stock.

---

## 🛠️ Tech Stack & Tools
*   **Data Processing & Modeling:** Python (`pandas`, `numpy`, `scipy`)
*   **Data Visualization & Analytics:** Tableau
*   **Data Profiling & Validation:** Microsoft Excel

---

## 📊 Core Business Metrics (KPIs)
*   **On-Time Delivery (OTD) Rate:** Percentage of supplier shipments arriving on or before the promised deadline.
*   **Safety Stock Levels:** Mathematically optimized buffer stock held to mitigate unexpected demand spikes or supplier delays.
*   **Inventory Turnover Ratio:** The frequency at which inventory is sold and replaced over a given period.
*   **Stockout Rate:** The percentage of time specific high-velocity items are out of stock, representing lost revenue.

---

## ⚙️ Implementation Steps

### 1. Data Aggregation & Cleaning (Python)
*   Consolidated and structured separate, fragmented relational tables (`Products_Master`, `Inventory_Levels`, and `Supplier_Performance`).
*   Handled missing values, formatted datetime logs, and engineered features tracking over 50,000+ transaction rows across 150+ unique SKUs.

### 2. Inventory Stratification (ABC/XYZ Matrix)
*   Classified product inventory based on revenue contribution (**ABC Analysis**) and demand predictability/volatility (**XYZ Analysis**).
*   Isolated high-value, highly volatile items requiring strict monitoring.

### 3. Statistical Safety Stock Modeling (SciPy)
*   Calculated standard deviations for demand variations and supplier lead times.
*   Applied standard statistical inventory formulas to establish dynamic, automated safety stock thresholds for each echelon (tier) of the network.

### 4. Interactive Dashboarding (Tableau)
*   Developed a comprehensive executive dashboard highlighting critical tracking streams.
*   Built automated visual alerts for supplier delays, low stock thresholds, and capital reallocation opportunities.

---

## 📈 Business Impact & Actionable Insights
*   **Solved Visibility Gaps:** Eliminated fragmented data issues that previously led to localized stock shortages while other echelons were choked with dead stock.
*   **Capital Optimization:** Enabled supply chain managers to confidently lower safety stock buffers for predictable items, freeing up locked working capital.
*   **Vendor Management:** Identified exact bottlenecks in vendor fulfillment, allowing procurement teams to renegotiate or drop low-performing supplier contracts based on historical OTD metrics.

---
