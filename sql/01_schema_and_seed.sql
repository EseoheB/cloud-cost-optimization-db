-- ============================================================================
-- 01_schema_and_seed.sql
-- Cloud Resource Management and Cost Optimization System
-- Author: Rabiat Blessing Ibrahim
-- Full schema (19 tables) and synthetic sample data, exported with mysqldump
-- from MySQL 8.0.44. Running this file resets the database to a clean state.
-- ============================================================================

DROP DATABASE IF EXISTS cloud_resource_management;
CREATE DATABASE cloud_resource_management;
USE cloud_resource_management;

-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: cloud_resource_management
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alert_recipient`
--

DROP TABLE IF EXISTS `alert_recipient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alert_recipient` (
  `Alert_Recipient_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Alert_ID` int NOT NULL,
  `FK_User_ID` int NOT NULL,
  `FK_Channel_ID` int NOT NULL,
  `Is_Active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Alert_Recipient_ID`),
  UNIQUE KEY `uk_alert_user_channel` (`FK_Alert_ID`,`FK_User_ID`,`FK_Channel_ID`),
  KEY `fk_alertrec_user` (`FK_User_ID`),
  KEY `fk_alertrec_channel` (`FK_Channel_ID`),
  CONSTRAINT `fk_alertrec_alert` FOREIGN KEY (`FK_Alert_ID`) REFERENCES `alert_rule` (`Alert_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alertrec_channel` FOREIGN KEY (`FK_Channel_ID`) REFERENCES `notification_channel` (`Channel_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alertrec_user` FOREIGN KEY (`FK_User_ID`) REFERENCES `user_account` (`User_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alert_recipient`
--

LOCK TABLES `alert_recipient` WRITE;
/*!40000 ALTER TABLE `alert_recipient` DISABLE KEYS */;
INSERT INTO `alert_recipient` VALUES (1,1,3,1,1),(2,1,2,2,1),(3,2,3,1,1),(4,2,2,2,1),(5,3,4,1,1),(6,3,4,2,1),(7,4,8,3,1),(8,5,11,4,1),(9,5,10,5,1),(10,6,18,6,1),(11,6,17,7,1),(12,7,18,6,1);
/*!40000 ALTER TABLE `alert_recipient` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alert_rule`
--

DROP TABLE IF EXISTS `alert_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alert_rule` (
  `Alert_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Project_ID` int NOT NULL,
  `Alert_Name` varchar(200) NOT NULL,
  `Threshold_Type` enum('budget_percentage','absolute_cost','resource_count','daily_spend') NOT NULL,
  `Threshold_Value` decimal(15,2) NOT NULL,
  `Is_Active` tinyint(1) NOT NULL DEFAULT '1',
  `Created_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Alert_ID`),
  KEY `fk_alert_project` (`FK_Project_ID`),
  CONSTRAINT `fk_alert_project` FOREIGN KEY (`FK_Project_ID`) REFERENCES `project` (`Project_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alert_rule`
--

LOCK TABLES `alert_rule` WRITE;
/*!40000 ALTER TABLE `alert_rule` DISABLE KEYS */;
INSERT INTO `alert_rule` VALUES (1,1,'E-Commerce Budget 80% Alert','budget_percentage',80.00,1,'2025-12-06 20:40:10'),(2,1,'E-Commerce Daily Spend Alert','daily_spend',500.00,1,'2025-12-06 20:40:10'),(3,3,'Analytics Pipeline Budget Alert','budget_percentage',75.00,1,'2025-12-06 20:40:10'),(4,5,'Customer Portal Cost Alert','absolute_cost',10000.00,1,'2025-12-06 20:40:10'),(5,7,'Inventory System Budget Alert','budget_percentage',90.00,1,'2025-12-06 20:40:10'),(6,13,'Payment Gateway Critical Alert','budget_percentage',85.00,1,'2025-12-06 20:40:10'),(7,13,'Payment Gateway Resource Count','resource_count',10.00,1,'2025-12-06 20:40:10');
/*!40000 ALTER TABLE `alert_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `billing_period`
--

DROP TABLE IF EXISTS `billing_period`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_period` (
  `Period_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Account_ID` int NOT NULL,
  `Start_Date` date NOT NULL,
  `End_Date` date NOT NULL,
  `Total_Cost` decimal(15,2) DEFAULT '0.00',
  `Invoice_Number` varchar(50) DEFAULT NULL,
  `Invoice_Status` enum('draft','finalized','paid','overdue') NOT NULL DEFAULT 'draft',
  `Due_Date` date DEFAULT NULL,
  PRIMARY KEY (`Period_ID`),
  UNIQUE KEY `uk_account_period` (`FK_Account_ID`,`Start_Date`),
  UNIQUE KEY `Invoice_Number` (`Invoice_Number`),
  KEY `idx_billing_account_date` (`FK_Account_ID`,`Start_Date`),
  CONSTRAINT `fk_billing_account` FOREIGN KEY (`FK_Account_ID`) REFERENCES `customer_account` (`Account_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_billing_dates` CHECK ((`End_Date` > `Start_Date`))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `billing_period`
--

LOCK TABLES `billing_period` WRITE;
/*!40000 ALTER TABLE `billing_period` DISABLE KEYS */;
INSERT INTO `billing_period` VALUES (1,1,'2024-10-01','2024-10-31',12350.75,'INV-2024-10-001','paid','2024-11-15'),(2,1,'2024-11-01','2024-11-30',15600.50,'INV-2024-11-001','finalized','2024-12-15'),(3,2,'2024-10-01','2024-10-31',9500.00,'INV-2024-10-002','paid','2024-11-15'),(4,2,'2024-11-01','2024-11-30',11200.00,'INV-2024-11-002','draft','2024-12-15'),(5,3,'2024-10-01','2024-10-31',18900.00,'INV-2024-10-003','paid','2024-11-15'),(6,3,'2024-11-01','2024-11-30',21500.00,'INV-2024-11-003','finalized','2024-12-15'),(7,6,'2024-10-01','2024-10-31',28500.00,'INV-2024-10-006','paid','2024-11-15'),(8,6,'2024-11-01','2024-11-30',32100.00,'INV-2024-11-006','finalized','2024-12-15');
/*!40000 ALTER TABLE `billing_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cost_center`
--

DROP TABLE IF EXISTS `cost_center`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cost_center` (
  `Cost_Center_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Account_ID` int NOT NULL,
  `FK_Cost_Center_ID` int DEFAULT NULL,
  `Cost_Center_Code` varchar(50) NOT NULL,
  `Cost_Center_Name` varchar(200) NOT NULL,
  `Description` text,
  `Is_Active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Cost_Center_ID`),
  UNIQUE KEY `uk_costcenter_code` (`FK_Account_ID`,`Cost_Center_Code`),
  KEY `idx_costcenter_parent` (`FK_Cost_Center_ID`),
  CONSTRAINT `fk_costcenter_account` FOREIGN KEY (`FK_Account_ID`) REFERENCES `customer_account` (`Account_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_costcenter_parent` FOREIGN KEY (`FK_Cost_Center_ID`) REFERENCES `cost_center` (`Cost_Center_ID`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cost_center`
--

LOCK TABLES `cost_center` WRITE;
/*!40000 ALTER TABLE `cost_center` DISABLE KEYS */;
INSERT INTO `cost_center` VALUES (1,1,NULL,'CC-001','Engineering','Engineering department',1),(2,1,1,'CC-001-A','Backend Development','Backend engineering team',1),(3,1,1,'CC-001-B','Frontend Development','Frontend engineering team',1),(4,1,NULL,'CC-002','Data Science','Data science and analytics',1),(5,1,NULL,'CC-003','Operations','IT Operations and infrastructure',1),(6,2,NULL,'TS-100','Product Development','Product development team',1),(7,2,NULL,'TS-200','Research','R&D department',1),(8,3,NULL,'GR-RETAIL','Retail Operations','Store systems and operations',1),(9,3,NULL,'GR-ANALYTICS','Business Analytics','Analytics and reporting',1),(10,6,NULL,'FT-PAYMENTS','Payment Systems','Payment processing infrastructure',1),(11,6,NULL,'FT-SECURITY','Security Operations','Security and compliance',1);
/*!40000 ALTER TABLE `cost_center` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer_account`
--

DROP TABLE IF EXISTS `customer_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_account` (
  `Account_ID` int NOT NULL AUTO_INCREMENT,
  `Company_Name` varchar(200) NOT NULL,
  `Account_Tier` enum('Basic','Professional','Enterprise') NOT NULL,
  `Account_Status` enum('Active','Suspended','Closed') NOT NULL DEFAULT 'Active',
  `FK_Primary_Contact_User_ID` int DEFAULT NULL,
  `FK_Billing_Contact_User_ID` int DEFAULT NULL,
  `Created_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Modified_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Account_ID`),
  KEY `fk_primary_contact` (`FK_Primary_Contact_User_ID`),
  KEY `fk_billing_contact` (`FK_Billing_Contact_User_ID`),
  CONSTRAINT `fk_billing_contact` FOREIGN KEY (`FK_Billing_Contact_User_ID`) REFERENCES `user_account` (`User_ID`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_primary_contact` FOREIGN KEY (`FK_Primary_Contact_User_ID`) REFERENCES `user_account` (`User_ID`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_account`
--

LOCK TABLES `customer_account` WRITE;
/*!40000 ALTER TABLE `customer_account` DISABLE KEYS */;
INSERT INTO `customer_account` VALUES (1,'Acme Corporation','Enterprise','Active',1,3,'2025-12-06 20:40:10','2025-12-06 20:40:10'),(2,'TechStart Inc','Professional','Active',6,8,'2025-12-06 20:40:10','2025-12-06 20:40:10'),(3,'Global Retail Ltd','Enterprise','Active',9,11,'2025-12-06 20:40:10','2025-12-06 20:40:10'),(4,'DataDrive Solutions','Basic','Active',12,12,'2025-12-06 20:40:10','2025-12-06 20:40:10'),(5,'Cloud Innovations','Professional','Suspended',14,14,'2025-12-06 20:40:10','2025-12-06 20:40:10'),(6,'FinTech Dynamics','Enterprise','Active',16,18,'2025-12-06 20:40:10','2025-12-06 20:40:10');
/*!40000 ALTER TABLE `customer_account` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoice_line_item`
--

DROP TABLE IF EXISTS `invoice_line_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_line_item` (
  `Line_Item_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Period_ID` int NOT NULL,
  `FK_Project_ID` int NOT NULL,
  `FK_Region_ID` int NOT NULL,
  `Line_Item_Cost` decimal(12,4) NOT NULL,
  `Description` text,
  PRIMARY KEY (`Line_Item_ID`),
  KEY `fk_lineitem_region` (`FK_Region_ID`),
  KEY `idx_lineitem_period` (`FK_Period_ID`),
  KEY `idx_lineitem_project` (`FK_Project_ID`),
  CONSTRAINT `fk_lineitem_period` FOREIGN KEY (`FK_Period_ID`) REFERENCES `billing_period` (`Period_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_lineitem_project` FOREIGN KEY (`FK_Project_ID`) REFERENCES `project` (`Project_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lineitem_region` FOREIGN KEY (`FK_Region_ID`) REFERENCES `region` (`Region_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_lineitem_cost` CHECK ((`Line_Item_Cost` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoice_line_item`
--

LOCK TABLES `invoice_line_item` WRITE;
/*!40000 ALTER TABLE `invoice_line_item` DISABLE KEYS */;
INSERT INTO `invoice_line_item` VALUES (1,1,1,1,8500.5000,'E-Commerce Platform - Production resources'),(2,1,2,2,2100.2500,'Mobile App Development - Dev environment'),(3,1,3,1,1750.0000,'Data Analytics Pipeline - Processing and storage'),(4,2,1,1,9800.7500,'E-Commerce Platform - Production resources'),(5,2,2,2,3200.5000,'Mobile App Development - Increased usage'),(6,2,3,1,2599.2500,'Data Analytics Pipeline - Heavy processing month'),(7,3,5,1,6200.0000,'Customer Portal - Production environment'),(8,3,6,2,3300.0000,'API Gateway - Staging resources'),(9,4,5,1,7100.0000,'Customer Portal - Production environment'),(10,4,6,2,4100.0000,'API Gateway - Staging resources'),(11,5,7,4,12500.0000,'Inventory Management - Multi-region deployment'),(12,5,8,4,6400.0000,'Point of Sale System - EU region'),(13,6,7,4,14200.0000,'Inventory Management - Peak season'),(14,6,8,4,7300.0000,'Point of Sale System - Increased transactions'),(15,7,13,1,19500.0000,'Payment Gateway - High availability setup'),(16,7,14,1,9000.0000,'Fraud Detection - ML processing'),(17,8,13,1,22100.0000,'Payment Gateway - Holiday season traffic'),(18,8,14,1,10000.0000,'Fraud Detection - Enhanced monitoring');
/*!40000 ALTER TABLE `invoice_line_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoice_usage_detail`
--

DROP TABLE IF EXISTS `invoice_usage_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_usage_detail` (
  `Event_Detail_ID` bigint NOT NULL AUTO_INCREMENT,
  `FK_Line_Item_ID` int NOT NULL,
  `FK_Event_ID` bigint NOT NULL,
  `Event_Cost` decimal(12,4) NOT NULL,
  PRIMARY KEY (`Event_Detail_ID`),
  UNIQUE KEY `uk_lineitem_event` (`FK_Line_Item_ID`,`FK_Event_ID`),
  KEY `idx_invusage_event` (`FK_Event_ID`),
  CONSTRAINT `fk_invusage_event` FOREIGN KEY (`FK_Event_ID`) REFERENCES `usage_event` (`Event_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_invusage_lineitem` FOREIGN KEY (`FK_Line_Item_ID`) REFERENCES `invoice_line_item` (`Line_Item_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoice_usage_detail`
--

LOCK TABLES `invoice_usage_detail` WRITE;
/*!40000 ALTER TABLE `invoice_usage_detail` DISABLE KEYS */;
INSERT INTO `invoice_usage_detail` VALUES (1,4,1,2.3040),(2,4,2,2.3040),(3,4,3,2.3040),(4,4,6,2.7600),(5,4,7,2.7600),(6,4,8,2.7600),(7,4,9,34.5000),(8,5,11,0.9980),(9,5,12,0.9980),(10,5,10,18.4000),(11,6,13,1.7280),(12,6,14,1.9200),(13,6,15,1.7280);
/*!40000 ALTER TABLE `invoice_usage_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notification_channel`
--

DROP TABLE IF EXISTS `notification_channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_channel` (
  `Channel_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Account_ID` int NOT NULL,
  `Channel_Type` enum('email','slack','sms','webhook','teams') NOT NULL,
  `Channel_Name` varchar(200) NOT NULL,
  `Channel_Config` text,
  `Is_Active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Channel_ID`),
  KEY `fk_channel_account` (`FK_Account_ID`),
  CONSTRAINT `fk_channel_account` FOREIGN KEY (`FK_Account_ID`) REFERENCES `customer_account` (`Account_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification_channel`
--

LOCK TABLES `notification_channel` WRITE;
/*!40000 ALTER TABLE `notification_channel` DISABLE KEYS */;
INSERT INTO `notification_channel` VALUES (1,1,'email','Acme Finance Team','{\"email\": \"finance@acme.com\"}',1),(2,1,'slack','Acme Engineering Alerts','{\"webhook\": \"https://hooks.slack.com/services/T00/B00/XXX\", \"channel\": \"#cloud-alerts\"}',1),(3,2,'email','TechStart Alerts','{\"email\": \"alerts@techstart.com\"}',1),(4,3,'email','Global Retail Finance','{\"email\": \"billing@globalretail.com\"}',1),(5,3,'teams','Retail Ops Team','{\"webhook\": \"https://outlook.office.com/webhook/xxx\"}',1),(6,6,'email','FinTech Security Team','{\"email\": \"security@fintechdynamics.com\"}',1),(7,6,'slack','FinTech Operations','{\"webhook\": \"https://hooks.slack.com/services/T00/B00/YYY\"}',1);
/*!40000 ALTER TABLE `notification_channel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pricing_tier`
--

DROP TABLE IF EXISTS `pricing_tier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pricing_tier` (
  `Pricing_Tier_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Region_ID` int NOT NULL,
  `FK_Resource_Type_Code` varchar(50) NOT NULL,
  `Rate_Per_Unit` decimal(12,6) NOT NULL,
  `Tier_Level` enum('on_demand','reserved_1yr','reserved_3yr','spot') NOT NULL,
  `Effective_Start_Date` date NOT NULL,
  `Effective_End_Date` date DEFAULT NULL,
  PRIMARY KEY (`Pricing_Tier_ID`),
  KEY `fk_pricing_region` (`FK_Region_ID`),
  KEY `fk_pricing_resourcetype` (`FK_Resource_Type_Code`),
  CONSTRAINT `fk_pricing_region` FOREIGN KEY (`FK_Region_ID`) REFERENCES `region` (`Region_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_pricing_resourcetype` FOREIGN KEY (`FK_Resource_Type_Code`) REFERENCES `resource_type` (`Resource_Type_Code`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_pricing_dates` CHECK (((`Effective_End_Date` is null) or (`Effective_End_Date` >= `Effective_Start_Date`))),
  CONSTRAINT `chk_rate_positive` CHECK ((`Rate_Per_Unit` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pricing_tier`
--

LOCK TABLES `pricing_tier` WRITE;
/*!40000 ALTER TABLE `pricing_tier` DISABLE KEYS */;
INSERT INTO `pricing_tier` VALUES (1,1,'EC2_T3_SMALL',0.020800,'on_demand','2024-01-01',NULL),(2,1,'EC2_T3_MEDIUM',0.041600,'on_demand','2024-01-01',NULL),(3,1,'EC2_M5_LARGE',0.096000,'on_demand','2024-01-01',NULL),(4,1,'S3_STANDARD',0.023000,'on_demand','2024-01-01',NULL),(5,1,'S3_GLACIER',0.004000,'on_demand','2024-01-01',NULL),(6,1,'RDS_MYSQL',0.115000,'on_demand','2024-01-01',NULL),(7,1,'RDS_POSTGRES',0.115000,'on_demand','2024-01-01',NULL),(8,1,'LAMBDA_REQUEST',0.000000,'on_demand','2024-01-01',NULL),(9,1,'CLOUDFRONT_DATA',0.085000,'on_demand','2024-01-01',NULL),(10,2,'EC2_T3_MEDIUM',0.041600,'on_demand','2024-01-01',NULL),(11,2,'EC2_M5_LARGE',0.096000,'on_demand','2024-01-01',NULL),(12,2,'RDS_POSTGRES',0.115000,'on_demand','2024-01-01',NULL),(13,2,'S3_STANDARD',0.023000,'on_demand','2024-01-01',NULL),(14,4,'EC2_M5_LARGE',0.107000,'on_demand','2024-01-01',NULL),(15,4,'RDS_POSTGRES',0.128000,'on_demand','2024-01-01',NULL),(16,4,'EBS_SSD',0.100000,'on_demand','2024-01-01',NULL);
/*!40000 ALTER TABLE `pricing_tier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project`
--

DROP TABLE IF EXISTS `project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project` (
  `Project_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Account_ID` int NOT NULL,
  `FK_Project_Owner_User_ID` int NOT NULL,
  `Project_Name` varchar(200) NOT NULL,
  `Budget_Allocation` decimal(15,2) DEFAULT NULL,
  `Current_Month_Spend` decimal(15,2) DEFAULT '0.00',
  `Environment_Type` enum('Development','Staging','Production','Testing') DEFAULT NULL,
  `Created_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Is_Active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Project_ID`),
  KEY `idx_project_account` (`FK_Account_ID`),
  KEY `idx_project_owner` (`FK_Project_Owner_User_ID`),
  CONSTRAINT `fk_project_account` FOREIGN KEY (`FK_Account_ID`) REFERENCES `customer_account` (`Account_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_project_owner` FOREIGN KEY (`FK_Project_Owner_User_ID`) REFERENCES `user_account` (`User_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_budget_positive` CHECK ((`Budget_Allocation` >= 0)),
  CONSTRAINT `chk_spend_positive` CHECK ((`Current_Month_Spend` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project`
--

LOCK TABLES `project` WRITE;
/*!40000 ALTER TABLE `project` DISABLE KEYS */;
INSERT INTO `project` VALUES (1,1,2,'E-Commerce Platform',50000.00,12350.75,'Production','2025-12-06 20:40:10',1),(2,1,2,'Mobile App Development',25000.00,8450.00,'Development','2025-12-06 20:40:10',1),(3,1,4,'Data Analytics Pipeline',35000.00,15200.50,'Production','2025-12-06 20:40:10',1),(4,1,2,'Testing Environment',10000.00,3200.00,'Testing','2025-12-06 20:40:10',1),(5,2,7,'Customer Portal',30000.00,9500.00,'Production','2025-12-06 20:40:10',1),(6,2,7,'API Gateway',20000.00,7800.00,'Staging','2025-12-06 20:40:10',1),(7,3,10,'Inventory Management',45000.00,18900.00,'Production','2025-12-06 20:40:10',1),(8,3,10,'Point of Sale System',40000.00,16500.00,'Production','2025-12-06 20:40:10',1),(9,3,10,'Analytics Dashboard',15000.00,4200.00,'Development','2025-12-06 20:40:10',1),(10,4,13,'Data Warehouse',28000.00,11200.00,'Production','2025-12-06 20:40:10',1),(11,4,13,'ETL Pipeline',18000.00,6800.00,'Staging','2025-12-06 20:40:10',1),(12,5,15,'Legacy System Migration',60000.00,22000.00,'Staging','2025-12-06 20:40:10',1),(13,6,17,'Payment Gateway',70000.00,28500.00,'Production','2025-12-06 20:40:10',1),(14,6,17,'Fraud Detection System',55000.00,21300.00,'Production','2025-12-06 20:40:10',1),(15,6,17,'Compliance Reporting',22000.00,7900.00,'Development','2025-12-06 20:40:10',1);
/*!40000 ALTER TABLE `project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_cost_center`
--

DROP TABLE IF EXISTS `project_cost_center`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_cost_center` (
  `Project_Cost_Center_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Project_ID` int NOT NULL,
  `FK_Cost_Center_ID` int NOT NULL,
  `Allocation_Percentage` decimal(5,2) NOT NULL,
  `Effective_Start_Date` date NOT NULL,
  `Effective_End_Date` date DEFAULT NULL,
  PRIMARY KEY (`Project_Cost_Center_ID`),
  KEY `fk_projcost_project` (`FK_Project_ID`),
  KEY `fk_projcost_center` (`FK_Cost_Center_ID`),
  CONSTRAINT `fk_projcost_center` FOREIGN KEY (`FK_Cost_Center_ID`) REFERENCES `cost_center` (`Cost_Center_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_projcost_project` FOREIGN KEY (`FK_Project_ID`) REFERENCES `project` (`Project_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_allocation_percentage` CHECK (((`Allocation_Percentage` > 0) and (`Allocation_Percentage` <= 100))),
  CONSTRAINT `chk_effective_dates` CHECK (((`Effective_End_Date` is null) or (`Effective_End_Date` >= `Effective_Start_Date`)))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_cost_center`
--

LOCK TABLES `project_cost_center` WRITE;
/*!40000 ALTER TABLE `project_cost_center` DISABLE KEYS */;
INSERT INTO `project_cost_center` VALUES (1,1,2,60.00,'2024-01-01',NULL),(2,1,3,40.00,'2024-01-01',NULL),(3,3,4,100.00,'2024-01-01',NULL),(4,5,6,100.00,'2024-01-01',NULL),(5,7,8,100.00,'2024-01-01',NULL),(6,13,10,100.00,'2024-01-01',NULL);
/*!40000 ALTER TABLE `project_cost_center` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_user_access`
--

DROP TABLE IF EXISTS `project_user_access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_user_access` (
  `Access_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Project_ID` int NOT NULL,
  `FK_User_ID` int NOT NULL,
  `Access_Level` enum('owner','editor','viewer','billing_only') NOT NULL,
  `Granted_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Granted_By_User_ID` int DEFAULT NULL,
  PRIMARY KEY (`Access_ID`),
  UNIQUE KEY `uk_project_user` (`FK_Project_ID`,`FK_User_ID`),
  KEY `fk_access_user` (`FK_User_ID`),
  CONSTRAINT `fk_access_project` FOREIGN KEY (`FK_Project_ID`) REFERENCES `project` (`Project_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_access_user` FOREIGN KEY (`FK_User_ID`) REFERENCES `user_account` (`User_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_user_access`
--

LOCK TABLES `project_user_access` WRITE;
/*!40000 ALTER TABLE `project_user_access` DISABLE KEYS */;
INSERT INTO `project_user_access` VALUES (1,1,1,'owner','2025-12-06 20:40:10',NULL),(2,1,2,'owner','2025-12-06 20:40:10',1),(3,1,3,'billing_only','2025-12-06 20:40:10',1),(4,1,4,'editor','2025-12-06 20:40:10',1),(5,1,5,'viewer','2025-12-06 20:40:10',1),(6,2,2,'owner','2025-12-06 20:40:10',1),(7,2,4,'editor','2025-12-06 20:40:10',2),(8,3,4,'owner','2025-12-06 20:40:10',1),(9,3,2,'editor','2025-12-06 20:40:10',4),(10,5,6,'owner','2025-12-06 20:40:10',NULL),(11,5,7,'owner','2025-12-06 20:40:10',6),(12,5,8,'billing_only','2025-12-06 20:40:10',6),(13,7,9,'owner','2025-12-06 20:40:10',NULL),(14,7,10,'owner','2025-12-06 20:40:10',9),(15,7,11,'billing_only','2025-12-06 20:40:10',9);
/*!40000 ALTER TABLE `project_user_access` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `region`
--

DROP TABLE IF EXISTS `region`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `region` (
  `Region_ID` int NOT NULL AUTO_INCREMENT,
  `Region_Code` varchar(50) NOT NULL,
  `Region_Name` varchar(200) NOT NULL,
  `Geographic_Location` varchar(200) DEFAULT NULL,
  `Cloud_Provider` enum('AWS','Azure','GCP','Multi-Cloud') NOT NULL,
  PRIMARY KEY (`Region_ID`),
  UNIQUE KEY `Region_Code` (`Region_Code`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `region`
--

LOCK TABLES `region` WRITE;
/*!40000 ALTER TABLE `region` DISABLE KEYS */;
INSERT INTO `region` VALUES (1,'us-east-1','US East (N. Virginia)','North America','AWS'),(2,'us-west-2','US West (Oregon)','North America','AWS'),(3,'us-west-1','US West (N. California)','North America','AWS'),(4,'eu-west-1','EU West (Ireland)','Europe','AWS'),(5,'eu-central-1','EU Central (Frankfurt)','Europe','AWS'),(6,'ap-southeast-1','Asia Pacific (Singapore)','Asia','AWS'),(7,'ap-northeast-1','Asia Pacific (Tokyo)','Asia','AWS'),(8,'sa-east-1','South America (São Paulo)','South America','AWS');
/*!40000 ALTER TABLE `region` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource`
--

DROP TABLE IF EXISTS `resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource` (
  `Resource_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Project_ID` int NOT NULL,
  `FK_Region_ID` int NOT NULL,
  `FK_Resource_Type_Code` varchar(50) NOT NULL,
  `Resource_Name` varchar(200) NOT NULL,
  `Current_Status` enum('active','stopped','terminated') NOT NULL DEFAULT 'active',
  `Creation_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Termination_Date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`Resource_ID`),
  KEY `fk_resource_region` (`FK_Region_ID`),
  KEY `idx_resource_project` (`FK_Project_ID`),
  KEY `idx_resource_type` (`FK_Resource_Type_Code`),
  KEY `idx_resource_status` (`Current_Status`),
  CONSTRAINT `fk_resource_project` FOREIGN KEY (`FK_Project_ID`) REFERENCES `project` (`Project_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_resource_region` FOREIGN KEY (`FK_Region_ID`) REFERENCES `region` (`Region_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_resource_type` FOREIGN KEY (`FK_Resource_Type_Code`) REFERENCES `resource_type` (`Resource_Type_Code`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource`
--

LOCK TABLES `resource` WRITE;
/*!40000 ALTER TABLE `resource` DISABLE KEYS */;
INSERT INTO `resource` VALUES (1,1,1,'EC2_M5_LARGE','ecommerce-web-server-01','active','2024-01-15 18:30:00',NULL),(2,1,1,'EC2_M5_LARGE','ecommerce-web-server-02','active','2024-01-15 18:35:00',NULL),(3,1,1,'RDS_MYSQL','ecommerce-db-primary','active','2024-01-15 19:00:00',NULL),(4,1,1,'S3_STANDARD','ecommerce-product-images','active','2024-01-15 17:00:00',NULL),(5,1,1,'CLOUDFRONT_DATA','ecommerce-cdn','active','2024-01-15 17:30:00',NULL),(6,2,2,'EC2_T3_MEDIUM','mobile-api-server','active','2024-02-01 22:00:00',NULL),(7,2,2,'RDS_POSTGRES','mobile-app-db','active','2024-02-01 22:30:00',NULL),(8,2,2,'S3_STANDARD','mobile-app-assets','active','2024-02-01 21:00:00',NULL),(9,3,1,'EC2_M5_LARGE','analytics-processing-01','active','2024-01-20 16:00:00',NULL),(10,3,1,'EC2_M5_LARGE','analytics-processing-02','active','2024-01-20 16:05:00',NULL),(11,3,1,'S3_STANDARD','analytics-raw-data','active','2024-01-20 15:00:00',NULL),(12,3,1,'S3_GLACIER','analytics-archive','active','2024-01-20 15:30:00',NULL),(13,5,1,'EC2_T3_MEDIUM','customer-portal-web','active','2024-03-01 18:00:00',NULL),(14,5,1,'RDS_MYSQL','customer-portal-db','active','2024-03-01 18:30:00',NULL),(15,5,1,'LAMBDA_REQUEST','customer-auth-function','active','2024-03-01 19:00:00',NULL),(16,7,4,'EC2_M5_LARGE','inventory-app-server','active','2024-02-15 17:00:00',NULL),(17,7,4,'RDS_POSTGRES','inventory-db-primary','active','2024-02-15 17:30:00',NULL),(18,7,4,'EBS_SSD','inventory-storage-vol','active','2024-02-15 17:15:00',NULL),(19,13,1,'EC2_M5_LARGE','payment-gateway-01','active','2024-01-10 16:00:00',NULL),(20,13,1,'EC2_M5_LARGE','payment-gateway-02','active','2024-01-10 16:05:00',NULL),(21,13,1,'RDS_POSTGRES','payment-transactions-db','active','2024-01-10 16:30:00',NULL),(22,13,2,'EC2_M5_LARGE','payment-gateway-backup','stopped','2024-01-10 17:00:00',NULL);
/*!40000 ALTER TABLE `resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource_tag`
--

DROP TABLE IF EXISTS `resource_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_tag` (
  `Resource_Tag_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Resource_ID` int NOT NULL,
  `FK_Tag_Key_ID` int NOT NULL,
  `Tag_Value` varchar(255) NOT NULL,
  PRIMARY KEY (`Resource_Tag_ID`),
  UNIQUE KEY `uk_resource_tagkey` (`FK_Resource_ID`,`FK_Tag_Key_ID`),
  KEY `fk_restag_tagkey` (`FK_Tag_Key_ID`),
  CONSTRAINT `fk_restag_resource` FOREIGN KEY (`FK_Resource_ID`) REFERENCES `resource` (`Resource_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_restag_tagkey` FOREIGN KEY (`FK_Tag_Key_ID`) REFERENCES `tag_key` (`Tag_Key_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource_tag`
--

LOCK TABLES `resource_tag` WRITE;
/*!40000 ALTER TABLE `resource_tag` DISABLE KEYS */;
INSERT INTO `resource_tag` VALUES (1,1,1,'Production'),(2,1,2,'Sarah Johnson'),(3,1,3,'CC-001-B'),(4,2,1,'Production'),(5,2,2,'Sarah Johnson'),(6,3,1,'Production'),(7,3,3,'CC-001-A'),(8,6,1,'Development'),(9,6,2,'Sarah Johnson'),(10,7,1,'Development'),(11,9,1,'Production'),(12,9,2,'Emily Rodriguez'),(13,9,3,'CC-002');
/*!40000 ALTER TABLE `resource_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource_type`
--

DROP TABLE IF EXISTS `resource_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_type` (
  `Resource_Type_Code` varchar(50) NOT NULL,
  `Resource_Type_Name` varchar(100) NOT NULL,
  `Resource_Type_Description` text,
  `Resource_Category` enum('Compute','Storage','Database','Network','Analytics','AI/ML','Other') NOT NULL,
  `Unit_Of_Measure` varchar(50) NOT NULL,
  PRIMARY KEY (`Resource_Type_Code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource_type`
--

LOCK TABLES `resource_type` WRITE;
/*!40000 ALTER TABLE `resource_type` DISABLE KEYS */;
INSERT INTO `resource_type` VALUES ('CLOUDFRONT_DATA','CloudFront Data Transfer','CDN data transfer','Network','GB'),('DYNAMODB_READ','DynamoDB Read Units','NoSQL database reads','Database','units'),('EBS_SSD','EBS SSD Volume','Block storage SSD','Storage','GB'),('EC2_M5_LARGE','EC2 M5 Large Instance','Large compute instance','Compute','hours'),('EC2_T3_MEDIUM','EC2 T3 Medium Instance','Medium compute instance','Compute','hours'),('EC2_T3_SMALL','EC2 T3 Small Instance','General purpose compute instance','Compute','hours'),('ELASTIC_IP','Elastic IP Address','Static IP address','Network','hours'),('LAMBDA_REQUEST','Lambda Function Invocation','Serverless compute','Compute','requests'),('RDS_MYSQL','RDS MySQL Database','Managed MySQL database','Database','hours'),('RDS_POSTGRES','RDS PostgreSQL Database','Managed PostgreSQL database','Database','hours'),('S3_GLACIER','S3 Glacier Storage','Archive storage','Storage','GB'),('S3_STANDARD','S3 Standard Storage','Standard object storage','Storage','GB');
/*!40000 ALTER TABLE `resource_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tag_key`
--

DROP TABLE IF EXISTS `tag_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tag_key` (
  `Tag_Key_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Account_ID` int NOT NULL,
  `Tag_Key_Name` varchar(100) NOT NULL,
  `Is_Required` tinyint(1) NOT NULL DEFAULT '0',
  `Description` text,
  PRIMARY KEY (`Tag_Key_ID`),
  UNIQUE KEY `uk_tagkey_name` (`FK_Account_ID`,`Tag_Key_Name`),
  CONSTRAINT `fk_tagkey_account` FOREIGN KEY (`FK_Account_ID`) REFERENCES `customer_account` (`Account_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tag_key`
--

LOCK TABLES `tag_key` WRITE;
/*!40000 ALTER TABLE `tag_key` DISABLE KEYS */;
INSERT INTO `tag_key` VALUES (1,1,'Environment',1,'Deployment environment'),(2,1,'Owner',1,'Resource owner'),(3,1,'CostCenter',1,'Cost allocation'),(4,1,'Project',0,'Project name'),(5,2,'Environment',1,'Deployment environment'),(6,2,'Team',0,'Team ownership'),(7,3,'Department',1,'Department allocation'),(8,3,'Region',0,'Business region');
/*!40000 ALTER TABLE `tag_key` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usage_event`
--

DROP TABLE IF EXISTS `usage_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usage_event` (
  `Event_ID` bigint NOT NULL AUTO_INCREMENT,
  `FK_Resource_ID` int NOT NULL,
  `FK_Pricing_Tier_ID` int NOT NULL,
  `Event_Timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Quantity_Consumed` decimal(15,6) NOT NULL,
  `Calculated_Cost` decimal(12,4) NOT NULL,
  `Event_Source` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`Event_ID`),
  KEY `fk_usage_pricing` (`FK_Pricing_Tier_ID`),
  KEY `idx_usage_timestamp` (`Event_Timestamp`),
  KEY `idx_usage_resource` (`FK_Resource_ID`,`Event_Timestamp`),
  CONSTRAINT `fk_usage_pricing` FOREIGN KEY (`FK_Pricing_Tier_ID`) REFERENCES `pricing_tier` (`Pricing_Tier_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_usage_resource` FOREIGN KEY (`FK_Resource_ID`) REFERENCES `resource` (`Resource_ID`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_cost_positive` CHECK ((`Calculated_Cost` >= 0)),
  CONSTRAINT `chk_quantity_positive` CHECK ((`Quantity_Consumed` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usage_event`
--

LOCK TABLES `usage_event` WRITE;
/*!40000 ALTER TABLE `usage_event` DISABLE KEYS */;
INSERT INTO `usage_event` VALUES (1,1,3,'2024-11-01 07:00:00',24.000000,2.3040,'CloudWatch'),(2,1,3,'2024-11-02 07:00:00',24.000000,2.3040,'CloudWatch'),(3,1,3,'2024-11-03 07:00:00',24.000000,2.3040,'CloudWatch'),(4,1,3,'2024-11-04 08:00:00',24.000000,2.3040,'CloudWatch'),(5,1,3,'2024-11-05 08:00:00',24.000000,2.3040,'CloudWatch'),(6,3,6,'2024-11-01 07:00:00',24.000000,2.7600,'CloudWatch'),(7,3,6,'2024-11-02 07:00:00',24.000000,2.7600,'CloudWatch'),(8,3,6,'2024-11-03 07:00:00',24.000000,2.7600,'CloudWatch'),(9,4,4,'2024-11-01 07:00:00',1500.000000,34.5000,'S3 Metrics'),(10,8,13,'2024-11-01 07:00:00',800.000000,18.4000,'S3 Metrics'),(11,6,10,'2024-11-01 07:00:00',24.000000,0.9980,'CloudWatch'),(12,6,10,'2024-11-02 07:00:00',24.000000,0.9980,'CloudWatch'),(13,9,3,'2024-11-01 07:00:00',18.000000,1.7280,'CloudWatch'),(14,9,3,'2024-11-02 07:00:00',20.000000,1.9200,'CloudWatch'),(15,10,3,'2024-11-01 07:00:00',18.000000,1.7280,'CloudWatch'),(16,13,10,'2024-11-01 07:00:00',24.000000,0.9980,'CloudWatch'),(17,14,11,'2024-11-01 07:00:00',24.000000,2.7600,'CloudWatch'),(18,15,8,'2024-11-01 07:00:00',50000.000000,8.3500,'Lambda Metrics'),(19,19,3,'2024-11-01 07:00:00',24.000000,2.3040,'CloudWatch'),(20,20,3,'2024-11-01 07:00:00',24.000000,2.3040,'CloudWatch'),(21,21,12,'2024-11-01 07:00:00',24.000000,2.7600,'CloudWatch');
/*!40000 ALTER TABLE `usage_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_account`
--

DROP TABLE IF EXISTS `user_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_account` (
  `User_ID` int NOT NULL AUTO_INCREMENT,
  `FK_Account_ID` int NOT NULL,
  `Full_Name` varchar(200) NOT NULL,
  `Email` varchar(255) NOT NULL,
  `User_Role` enum('admin','finance_manager','cloud_engineer','data_analyst','viewer') NOT NULL,
  `Is_Active` tinyint(1) NOT NULL DEFAULT '1',
  `Created_Date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Last_Login` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`User_ID`),
  UNIQUE KEY `Email` (`Email`),
  KEY `idx_user_email` (`Email`),
  KEY `idx_user_account` (`FK_Account_ID`),
  CONSTRAINT `fk_user_account` FOREIGN KEY (`FK_Account_ID`) REFERENCES `customer_account` (`Account_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_account`
--

LOCK TABLES `user_account` WRITE;
/*!40000 ALTER TABLE `user_account` DISABLE KEYS */;
INSERT INTO `user_account` VALUES (1,1,'John Smith','john.smith@acme.com','admin',1,'2025-12-06 20:40:10',NULL),(2,1,'Sarah Johnson','sarah.johnson@acme.com','cloud_engineer',1,'2025-12-06 20:40:10',NULL),(3,1,'Michael Chen','michael.chen@acme.com','finance_manager',1,'2025-12-06 20:40:10',NULL),(4,1,'Emily Rodriguez','emily.rodriguez@acme.com','data_analyst',1,'2025-12-06 20:40:10',NULL),(5,1,'David Kim','david.kim@acme.com','viewer',1,'2025-12-06 20:40:10',NULL),(6,2,'Lisa Wong','lisa.wong@techstart.com','admin',1,'2025-12-06 20:40:10',NULL),(7,2,'James Taylor','james.taylor@techstart.com','cloud_engineer',1,'2025-12-06 20:40:10',NULL),(8,2,'Maria Garcia','maria.garcia@techstart.com','finance_manager',1,'2025-12-06 20:40:10',NULL),(9,3,'Robert Anderson','robert.anderson@globalretail.com','admin',1,'2025-12-06 20:40:10',NULL),(10,3,'Jennifer Lee','jennifer.lee@globalretail.com','cloud_engineer',1,'2025-12-06 20:40:10',NULL),(11,3,'Thomas White','thomas.white@globalretail.com','finance_manager',1,'2025-12-06 20:40:10',NULL),(12,4,'Patricia Martinez','patricia.martinez@datadrive.com','admin',1,'2025-12-06 20:40:10',NULL),(13,4,'Daniel Brown','daniel.brown@datadrive.com','cloud_engineer',1,'2025-12-06 20:40:10',NULL),(14,5,'Jessica Wilson','jessica.wilson@cloudinnovations.com','admin',0,'2025-12-06 20:40:10',NULL),(15,5,'Christopher Davis','christopher.davis@cloudinnovations.com','cloud_engineer',1,'2025-12-06 20:40:10',NULL),(16,6,'Amanda Thompson','amanda.thompson@fintechdynamics.com','admin',1,'2025-12-06 20:40:10',NULL),(17,6,'Ryan Miller','ryan.miller@fintechdynamics.com','cloud_engineer',1,'2025-12-06 20:40:10',NULL),(18,6,'Michelle Moore','michelle.moore@fintechdynamics.com','finance_manager',1,'2025-12-06 20:40:10',NULL);
/*!40000 ALTER TABLE `user_account` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-06 15:31:03
