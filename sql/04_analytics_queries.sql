/* ============================================================================
   04_analytics_queries.sql
   Cloud Resource Management and Cost Optimization System
   Author: Rabiat Blessing Ibrahim

   Reporting queries behind the Tableau dashboards, plus scorecards and an
   invoice reconciliation check. Sample results in the README come from
   running this file right after 01 and 02, before the walkthrough.
   ============================================================================
*/

USE cloud_resource_management;

/* Reporting month for the time-based queries. The sample usage data covers
   November 2024. Change this value to report on another month. */
SET @report_month = DATE('2024-11-01');

/* ============================================================================
   QUERY 1: EXECUTIVE DASHBOARD - MONTHLY SPENDING OVERVIEW
   ============================================================================
*/

SELECT 
    customer.Company_Name,
    COUNT(DISTINCT project.Project_ID) AS 'Projects',
    CONCAT('$', FORMAT(SUM(project.Budget_Allocation), 2)) AS 'Budget',
    CONCAT('$', FORMAT(SUM(project.Current_Month_Spend), 2)) AS 'Spend',
    CONCAT(
        FORMAT((SUM(project.Current_Month_Spend) / SUM(project.Budget_Allocation)) * 100, 1), 
        '%'
    ) AS 'Utilization'
FROM CUSTOMER_ACCOUNT customer
INNER JOIN PROJECT project 
    ON customer.Account_ID = project.FK_Account_ID
WHERE project.Is_Active = TRUE
GROUP BY customer.Company_Name
ORDER BY SUM(project.Current_Month_Spend) DESC;

/* Expected Output: Summary showing each company's total projects, budgets, and spending
   Visualization: Horizontal bar chart comparing budget vs actual spend by company
*/


/* ============================================================================
   QUERY 2: COST CENTER ALLOCATION REPORT
   ============================================================================
*/

SELECT 
    cost_center.Cost_Center_Name AS 'Department',
    COUNT(DISTINCT project.Project_ID) AS 'Projects',
    CONCAT('$', FORMAT(
        SUM(usage_event.Calculated_Cost * (project_cost_center.Allocation_Percentage / 100)), 
        2
    )) AS 'Cost'
FROM COST_CENTER cost_center
INNER JOIN PROJECT_COST_CENTER project_cost_center 
    ON cost_center.Cost_Center_ID = project_cost_center.FK_Cost_Center_ID
INNER JOIN PROJECT project 
    ON project_cost_center.FK_Project_ID = project.Project_ID
INNER JOIN RESOURCE resource 
    ON project.Project_ID = resource.FK_Project_ID
INNER JOIN USAGE_EVENT usage_event 
    ON resource.Resource_ID = usage_event.FK_Resource_ID
WHERE cost_center.Is_Active = TRUE
GROUP BY cost_center.Cost_Center_Name
ORDER BY SUM(usage_event.Calculated_Cost * (project_cost_center.Allocation_Percentage / 100)) DESC;

/* Expected Output: List of departments with their project count and allocated costs
   Visualization: Pie chart showing percentage of total spend by department
*/


/* ============================================================================
   QUERY 3: TOP COST-CONSUMING RESOURCES
   ============================================================================
*/

SELECT 
    resource.Resource_Name,
    resource_type.Resource_Type_Name,
    CONCAT('$', FORMAT(SUM(usage_event.Calculated_Cost), 2)) AS 'Month Cost',
    CONCAT(
        FORMAT(
            SUM(usage_event.Calculated_Cost) / 
            SUM(SUM(usage_event.Calculated_Cost)) OVER () * 100, 
            1
        ), 
        '%'
    ) AS '% of Total'
FROM USAGE_EVENT usage_event
INNER JOIN RESOURCE resource 
    ON usage_event.FK_Resource_ID = resource.Resource_ID
INNER JOIN RESOURCE_TYPE resource_type 
    ON resource.FK_Resource_Type_Code = resource_type.Resource_Type_Code
WHERE usage_event.Event_Timestamp >= @report_month
  AND usage_event.Event_Timestamp < @report_month + INTERVAL 1 MONTH
GROUP BY resource.Resource_Name, resource_type.Resource_Type_Name
ORDER BY SUM(usage_event.Calculated_Cost) DESC
LIMIT 20;

/* Expected Output: Top 20 resources for @report_month sorted by cost with percentage of total
   Visualization: Table with conditional formatting highlighting resources over 10% of total
*/


/* ============================================================================
   BONUS QUERY 1: BUDGET ALERT STATUS DASHBOARD
   ============================================================================
*/

SELECT 
    customer.Company_Name,
    project.Project_Name,
    user.Full_Name AS 'Owner',
    CONCAT('$', FORMAT(project.Budget_Allocation, 2)) AS 'Budget',
    CONCAT('$', FORMAT(project.Current_Month_Spend, 2)) AS 'Spend',
    CONCAT(
        FORMAT((project.Current_Month_Spend / project.Budget_Allocation) * 100, 1), 
        '%'
    ) AS 'Used',
    CASE 
        WHEN (project.Current_Month_Spend / project.Budget_Allocation) >= 1.0 
        THEN 'OVER BUDGET'
        WHEN (project.Current_Month_Spend / project.Budget_Allocation) >= 0.90 
        THEN 'CRITICAL'
        WHEN (project.Current_Month_Spend / project.Budget_Allocation) >= 0.75 
        THEN 'WARNING'
        ELSE 'HEALTHY'
    END AS 'Status'
FROM PROJECT project
INNER JOIN CUSTOMER_ACCOUNT customer 
    ON project.FK_Account_ID = customer.Account_ID
INNER JOIN USER_ACCOUNT user 
    ON project.FK_Project_Owner_User_ID = user.User_ID
WHERE project.Is_Active = TRUE
ORDER BY (project.Current_Month_Spend / project.Budget_Allocation) DESC;

/* Expected Output: All projects with budget status color-coded
   Visualization: Traffic light dashboard with color-coded status indicators
*/


/* ============================================================================
   BONUS QUERY 2: RESOURCE CATEGORY SPENDING ANALYSIS
   ============================================================================
*/

SELECT 
    customer.Company_Name,
    resource_type.Resource_Category AS 'Category',
    COUNT(DISTINCT resource.Resource_ID) AS 'Resources',
    CONCAT('$', FORMAT(SUM(usage_event.Calculated_Cost), 2)) AS 'Total Cost',
    CONCAT(
        FORMAT(
            SUM(usage_event.Calculated_Cost) / 
            SUM(SUM(usage_event.Calculated_Cost)) OVER (PARTITION BY customer.Company_Name) * 100,
            1
        ),
        '%'
    ) AS '% of Company Total'
FROM USAGE_EVENT usage_event
INNER JOIN RESOURCE resource 
    ON usage_event.FK_Resource_ID = resource.Resource_ID
INNER JOIN RESOURCE_TYPE resource_type 
    ON resource.FK_Resource_Type_Code = resource_type.Resource_Type_Code
INNER JOIN PROJECT project 
    ON resource.FK_Project_ID = project.Project_ID
INNER JOIN CUSTOMER_ACCOUNT customer 
    ON project.FK_Account_ID = customer.Account_ID
GROUP BY customer.Company_Name, resource_type.Resource_Category
ORDER BY customer.Company_Name, SUM(usage_event.Calculated_Cost) DESC;

/* Expected Output: Breakdown of spending by resource category per company
   Visualization: Stacked bar chart showing category distribution by company
*/


/* ============================================================================
   BONUS QUERY 3: PROJECT PERFORMANCE SCORECARD
   ============================================================================
*/

SELECT 
    customer.Company_Name,
    project.Project_Name,
    user.Full_Name AS 'Owner',
    project.Environment_Type AS 'Environment',
    COUNT(DISTINCT resource.Resource_ID) AS 'Resources',
    CONCAT('$', FORMAT(project.Budget_Allocation, 2)) AS 'Budget',
    CONCAT('$', FORMAT(project.Current_Month_Spend, 2)) AS 'Spend',
    CONCAT(
        FORMAT((project.Current_Month_Spend / project.Budget_Allocation) * 100, 1),
        '%'
    ) AS 'Budget Used',
    CONCAT('$', FORMAT(
        project.Current_Month_Spend / NULLIF(COUNT(DISTINCT resource.Resource_ID), 0),
        2
    )) AS 'Cost per Resource',
    CASE 
        WHEN (project.Current_Month_Spend / project.Budget_Allocation) > 1.0 
            THEN '🔴 Critical'
        WHEN (project.Current_Month_Spend / project.Budget_Allocation) > 0.85 
            THEN '🟡 At Risk'
        WHEN COUNT(DISTINCT resource.Resource_ID) = 0 
            THEN '⚪ Inactive'
        ELSE '🟢 Healthy'
    END AS 'Health'
FROM PROJECT project
INNER JOIN CUSTOMER_ACCOUNT customer 
    ON project.FK_Account_ID = customer.Account_ID
INNER JOIN USER_ACCOUNT user 
    ON project.FK_Project_Owner_User_ID = user.User_ID
LEFT JOIN RESOURCE resource 
    ON project.Project_ID = resource.FK_Project_ID 
    AND resource.Current_Status = 'active'
WHERE project.Is_Active = TRUE
GROUP BY project.Project_ID, customer.Company_Name, project.Project_Name,
         user.Full_Name, project.Environment_Type, project.Budget_Allocation,
         project.Current_Month_Spend
ORDER BY customer.Company_Name, project.Project_Name;

/* Expected Output: Comprehensive project scorecard with health indicators
   Visualization: Dashboard with KPI cards for each project
*/

/* ============================================================================
   BONUS QUERY 4: INVOICE RECONCILIATION CHECK
   ============================================================================
   Compares each invoice line item with the metered usage events linked to it
   through INVOICE_USAGE_DETAIL. Line items with no linked usage, or where the
   billed amount and metered cost differ, need review before the invoice is
   finalized.
*/

SELECT 
    billing_period.Invoice_Number,
    billing_period.Invoice_Status,
    project.Project_Name,
    CONCAT('$', FORMAT(line_item.Line_Item_Cost, 2)) AS 'Billed',
    COUNT(usage_detail.FK_Event_ID) AS 'Linked Events',
    CONCAT('$', FORMAT(COALESCE(SUM(usage_detail.Event_Cost), 0), 2)) AS 'Metered',
    CASE 
        WHEN COUNT(usage_detail.FK_Event_ID) = 0 THEN 'NO USAGE LINKED'
        WHEN ABS(line_item.Line_Item_Cost - SUM(usage_detail.Event_Cost)) > 0.01 THEN 'MISMATCH'
        ELSE 'RECONCILED'
    END AS 'Check'
FROM INVOICE_LINE_ITEM line_item
INNER JOIN BILLING_PERIOD billing_period 
    ON line_item.FK_Period_ID = billing_period.Period_ID
INNER JOIN PROJECT project 
    ON line_item.FK_Project_ID = project.Project_ID
LEFT JOIN INVOICE_USAGE_DETAIL usage_detail 
    ON usage_detail.FK_Line_Item_ID = line_item.Line_Item_ID
GROUP BY line_item.Line_Item_ID, billing_period.Invoice_Number, 
         billing_period.Invoice_Status, project.Project_Name, 
         line_item.Line_Item_Cost, billing_period.Start_Date
ORDER BY billing_period.Start_Date DESC, billing_period.Invoice_Number;

/* Expected Output: One row per line item with billed vs metered cost and a check status
   Visualization: Table filtered to rows that are not RECONCILED
*/


/* ============================================================================
   DATA EXPORT: JOINED DATASET FOR TABLEAU
   ============================================================================
   Flattened view of customers, projects, owners, resources, regions, and usage.
*/
SELECT 
    customer.Company_Name,
    customer.Account_Tier,
    project.Project_Name,
    project.Environment_Type,
    user.Full_Name AS Project_Owner,
    resource.Resource_Name,
    resource_type.Resource_Type_Name,
    resource_type.Resource_Category,
    region.Region_Name,
    usage_event.Event_Timestamp,
    usage_event.Quantity_Consumed,
    usage_event.Calculated_Cost,
    project.Budget_Allocation,
    project.Current_Month_Spend
FROM CUSTOMER_ACCOUNT customer
INNER JOIN PROJECT project ON customer.Account_ID = project.FK_Account_ID
INNER JOIN USER_ACCOUNT user ON project.FK_Project_Owner_User_ID = user.User_ID
INNER JOIN RESOURCE resource ON project.Project_ID = resource.FK_Project_ID
INNER JOIN RESOURCE_TYPE resource_type ON resource.FK_Resource_Type_Code = resource_type.Resource_Type_Code
INNER JOIN REGION region ON resource.FK_Region_ID = region.Region_ID
LEFT JOIN USAGE_EVENT usage_event ON resource.Resource_ID = usage_event.FK_Resource_ID
WHERE project.Is_Active = TRUE
ORDER BY customer.Company_Name, project.Project_Name, resource.Resource_Name;

/* ============================================================================
   END OF ANALYTICS QUERIES
   ============================================================================
*/