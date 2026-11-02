# Dubai Airbnb Market Analytics

End-to-end data analytics project analyzing the Dubai short-term rental market. This project explores pricing trends, host performance, and property characteristics across thousands of Airbnb listings using **Python, SQL, and Power BI**.

## 📊 Power BI Dashboard

### Executive Overview
![Page 1](page1_executive.png)

### Host & Property Deep Dive
![Page 2](page2_host_property.png)

## 📋 Business Problem
Dubai's tourism and short-term rental market is booming. Investors and property managers need to know:
- Which property types generate the highest revenue?
- Does being a "Superhost" actually increase total revenue?
- How does the number of bedrooms impact the Average Daily Rate (ADR)?

## 🤖 AI-Native Workflow
This project was built using an AI-Native Workflow. I used Generative AI (ChatGPT) as a co-pilot to accelerate development, while maintaining strict human oversight.

- **AI for Python:** AI generated the Pandas pipeline to handle missing values, convert date formats, and cap extreme outliers.
- **AI for SQL:** AI generated 15 complex SQL queries using CTEs and Window Functions (e.g., `LAG` for MoM growth).
- **Human Validation:** I manually verified all AI-generated logic. For example, I noticed the `neighborhood` column was missing for 63% of the data, so I pivoted the dashboard to use `latitude/longitude` for geospatial mapping and `property_type` for categorical analysis.

## 📈 Key Insights
1. **Revenue Concentration:** The vast majority of market revenue is driven by "Entire home/apt" listings.
2. **The Superhost Paradox:** While Superhosts have higher occupancy per listing, **Regular Hosts generate significantly more total revenue** (26.4M vs 14.1M) due to their sheer volume in the market.
3. **Bedrooms Drive Price:** Listings with 4 to 5 bedrooms command the highest ADR, peaking at over AED 1,000 per night.

## 🛠️ Tools Used
- **Python (Pandas):** Data cleaning and outlier capping.
- **MySQL:** 15 advanced business queries.
- **Power BI:** 2-page interactive dashboard with custom UI/UX.
- **GenAI:** Prompt engineering, code generation, and validation.

## 👤 Author
**Yusuf Baig** — Data Analyst | SQL · Power BI · Python
- LinkedIn: [linkedin.com/in/yusuf-baig-783906210](https://www.linkedin.com/in/yusuf-baig-783906210/)
- GitHub: [@Yusufbaig2001](https://github.com/Yusufbaig2001)
