mysql> TRUNCATE TABLE transactions;
Query OK, 0 rows affected (0.13 sec)

mysql> SELECT COUNT(*) FROM transactions;
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
1 row in set (0.02 sec)

mysql> LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data.csv'
    -> INTO TABLE transactions
    -> CHARACTER SET LATIN1    -- FIX: Yeh line zaroori hai
    -> FIELDS TERMINATED BY ','
    -> ENCLOSED BY '"'
    -> LINES TERMINATED BY '\r\n'
    -> IGNORE 1 ROWS
    -> (InvoiceNo, StockCode, @Description, Quantity, InvoiceDate, UnitPrice, @CustomerID, Country)
    -> SET
    ->     Description = NULLIF(@Description, ''),
    ->     CustomerID = NULLIF(@CustomerID, '');
Query OK, 541909 rows affected, 4 warnings (12.89 sec)
Records: 541909  Deleted: 0  Skipped: 0  Warnings: 4

mysql> SELECT COUNT(*) FROM transactions;
+----------+
| COUNT(*) |
+----------+
|   541909 |
+----------+
1 row in set (0.07 sec)

mysql> UPDATE transactions
    -> SET invoice_date_clean = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
    -> WHERE InvoiceDate IS NOT NULL
    ->   AND InvoiceDate NOT LIKE '%S%';
Query OK, 541909 rows affected (36.02 sec)
Rows matched: 541909  Changed: 541909  Warnings: 0

mysql> SELECT COUNT(invoice_date_clean) AS dates_updated_count
    -> FROM transactions;
+---------------------+
| dates_updated_count |
+---------------------+
|              541909 |
+---------------------+
1 row in set (0.65 sec)

mysql> SELECT InvoiceDate, invoice_date_clean
    -> FROM transactions
    -> WHERE invoice_date_clean IS NOT NULL
    -> LIMIT 5;
+----------------+---------------------+
| InvoiceDate    | invoice_date_clean  |
+----------------+---------------------+
| 12/1/2010 8:26 | 2010-12-01 08:26:00 |
| 12/1/2010 8:26 | 2010-12-01 08:26:00 |
| 12/1/2010 8:26 | 2010-12-01 08:26:00 |
| 12/1/2010 8:26 | 2010-12-01 08:26:00 |
| 12/1/2010 8:26 | 2010-12-01 08:26:00 |
+----------------+---------------------+
5 rows in set (0.00 sec)

mysql> SELECT
    ->     COUNT(DISTINCT InvoiceNo) as total_invoices,
    ->     COUNT(DISTINCT CustomerID) as total_customers,
    ->     SUM(Quantity * UnitPrice) as total_revenue,
    ->     AVG(Quantity * UnitPrice) as avg_transaction_value,
    ->     SUM(Quantity) as total_items_sold
    -> FROM transactions
    -> WHERE Quantity > 0
    ->   AND UnitPrice > 0
    ->   AND CustomerID IS NOT NULL;
+----------------+-----------------+---------------+-----------------------+------------------+
| total_invoices | total_customers | total_revenue | avg_transaction_value | total_items_sold |
+----------------+-----------------+---------------+-----------------------+------------------+
|          18532 |            4338 |    8911407.90 |             22.397225 |          5167808 |
+----------------+-----------------+---------------+-----------------------+------------------+
1 row in set (2.74 sec)

mysql> -- Monthly Sales Performance
mysql> SELECT
    ->     DATE_FORMAT(invoice_date_clean, '%Y-%m') as month,
    ->     COUNT(DISTINCT InvoiceNo) as monthly_invoices,
    ->     COUNT(DISTINCT CustomerID) as unique_customers,
    ->     SUM(Quantity * UnitPrice) as monthly_revenue,
    ->     AVG(Quantity * UnitPrice) as avg_order_value
    -> FROM transactions
    -> WHERE invoice_date_clean IS NOT NULL
    ->   AND Quantity > 0
    ->   AND UnitPrice > 0
    -> GROUP BY month
    -> ORDER BY month;
+---------+------------------+------------------+-----------------+-----------------+
| month   | monthly_invoices | unique_customers | monthly_revenue | avg_order_value |
+---------+------------------+------------------+-----------------+-----------------+
| 2010-12 |             1559 |              885 |       823746.14 |       19.858875 |
| 2011-01 |             1086 |              741 |       691364.56 |       20.152876 |
| 2011-02 |             1100 |              758 |       523631.89 |       19.318646 |
| 2011-03 |             1454 |              974 |       717639.36 |       20.044113 |
| 2011-04 |             1246 |              856 |       537808.62 |       18.484572 |
| 2011-05 |             1681 |             1056 |       770536.02 |       21.306714 |
| 2011-06 |             1533 |              991 |       761739.90 |       21.172969 |
| 2011-07 |             1475 |              949 |       719221.19 |       18.611458 |
| 2011-08 |             1361 |              935 |       759138.38 |       22.014859 |
| 2011-09 |             1837 |             1266 |      1058590.17 |       21.490289 |
| 2011-10 |             2040 |             1364 |      1154979.30 |       19.475572 |
| 2011-11 |             2769 |             1664 |      1509496.33 |       18.106207 |
| 2011-12 |              819 |              615 |       638792.68 |       25.438759 |
+---------+------------------+------------------+-----------------+-----------------+
13 rows in set (3.32 sec)

mysql> -- Top 10 Products by Revenue
mysql> SELECT
    ->     StockCode,
    ->     Description,
    ->     SUM(Quantity) as total_quantity_sold,
    ->     COUNT(DISTINCT InvoiceNo) as times_ordered,
    ->     ROUND(SUM(Quantity * UnitPrice), 2) as total_revenue,
    ->     ROUND(AVG(UnitPrice), 2) as avg_unit_price
    -> FROM transactions
    -> WHERE Quantity > 0
    ->   AND UnitPrice > 0
    ->   AND Description IS NOT NULL
    -> GROUP BY StockCode, Description
    -> ORDER BY total_revenue DESC
    -> LIMIT 10;
+-----------+------------------------------------+---------------------+---------------+---------------+----------------+
| StockCode | Description                        | total_quantity_sold | times_ordered | total_revenue | avg_unit_price |
+-----------+------------------------------------+---------------------+---------------+---------------+----------------+
| DOT       | DOTCOM POSTAGE                     |                 706 |           706 |     206248.77 |         292.14 |
| 22423     | REGENCY CAKESTAND 3 TIER           |               13879 |          1988 |     174484.74 |          13.98 |
| 23843     | PAPER CRAFT , LITTLE BIRDIE        |               80995 |             1 |     168469.60 |           2.08 |
| 85123A    | WHITE HANGING HEART T-LIGHT HOLDER |               37891 |          2256 |     106292.77 |           3.22 |
| 47566     | PARTY BUNTING                      |               18295 |          1685 |      99504.33 |           5.79 |
| 85099B    | JUMBO BAG RED RETROSPOT            |               48474 |          2089 |      94340.05 |           2.49 |
| 23166     | MEDIUM CERAMIC TOP STORAGE JAR     |               78033 |           247 |      81700.92 |           1.47 |
| M         | Manual                             |                7225 |           290 |      78112.82 |         230.15 |
| POST      | POSTAGE                            |                3150 |          1126 |      78101.88 |          31.08 |
| 23084     | RABBIT NIGHT LIGHT                 |               30788 |           994 |      66964.99 |           2.38 |
+-----------+------------------------------------+---------------------+---------------+---------------+----------------+
10 rows in set (3.94 sec)

mysql> -- Geographic Revenue Distribution
mysql> SELECT
    ->     Country,
    ->     COUNT(DISTINCT CustomerID) as total_customers,
    ->     COUNT(DISTINCT InvoiceNo) as total_orders,
    ->     SUM(Quantity) as total_items,
    ->     ROUND(SUM(Quantity * UnitPrice), 2) as total_revenue,
    ->     ROUND(AVG(Quantity * UnitPrice), 2) as avg_order_value
    -> FROM transactions
    -> WHERE Quantity > 0
    ->   AND UnitPrice > 0
    ->   AND CustomerID IS NOT NULL
    -> GROUP BY Country
    -> ORDER BY total_revenue DESC
    -> LIMIT 15;
+----------------+-----------------+--------------+-------------+---------------+-----------------+
| Country        | total_customers | total_orders | total_items | total_revenue | avg_order_value |
+----------------+-----------------+--------------+-------------+---------------+-----------------+
| United Kingdom |            3920 |        16646 |     4256736 |    7308391.55 |           20.63 |
| Netherlands    |               9 |           94 |      200361 |     285446.34 |          121.00 |
| EIRE           |               3 |          260 |      140275 |     265545.90 |           36.70 |
| Germany        |              94 |          457 |      119261 |     228867.14 |           25.32 |
| France         |              87 |          389 |      111471 |     209024.05 |           25.06 |
| Australia      |               9 |           57 |       83901 |     138521.31 |          117.19 |
| Spain          |              30 |           90 |       27940 |      61577.11 |           24.79 |
| Switzerland    |              21 |           51 |       30082 |      56443.95 |           30.66 |
| Belgium        |              25 |           98 |       23237 |      41196.34 |           20.28 |
| Sweden         |               8 |           36 |       36083 |      38378.33 |           85.10 |
| Japan          |               8 |           19 |       26016 |      37416.37 |          116.56 |
| Norway         |              10 |           36 |       19336 |      36165.44 |           33.77 |
| Portugal       |              19 |           57 |       16122 |      33439.89 |           22.87 |
| Finland        |              12 |           41 |       10704 |      22546.08 |           32.91 |
| Singapore      |               1 |            7 |        5241 |      21279.29 |           95.85 |
+----------------+-----------------+--------------+-------------+---------------+-----------------+
15 rows in set (3.05 sec)

mysql> -- Geographic Revenue Distribution
mysql> SELECT
    ->     Country,
    ->     COUNT(DISTINCT CustomerID) as total_customers,
    ->     COUNT(DISTINCT InvoiceNo) as total_orders,
    ->     SUM(Quantity) as total_items,
    ->     ROUND(SUM(Quantity * UnitPrice), 2) as total_revenue,
    ->     ROUND(AVG(Quantity * UnitPrice), 2) as avg_order_value
    -> FROM transactions
    -> WHERE Quantity > 0
    ->   AND UnitPrice > 0
    ->   AND CustomerID IS NOT NULL
    -> GROUP BY Country
    -> ORDER BY total_revenue DESC
    -> LIMIT 15;
+----------------+-----------------+--------------+-------------+---------------+-----------------+
| Country        | total_customers | total_orders | total_items | total_revenue | avg_order_value |
+----------------+-----------------+--------------+-------------+---------------+-----------------+
| United Kingdom |            3920 |        16646 |     4256736 |    7308391.55 |           20.63 |
| Netherlands    |               9 |           94 |      200361 |     285446.34 |          121.00 |
| EIRE           |               3 |          260 |      140275 |     265545.90 |           36.70 |
| Germany        |              94 |          457 |      119261 |     228867.14 |           25.32 |
| France         |              87 |          389 |      111471 |     209024.05 |           25.06 |
| Australia      |               9 |           57 |       83901 |     138521.31 |          117.19 |
| Spain          |              30 |           90 |       27940 |      61577.11 |           24.79 |
| Switzerland    |              21 |           51 |       30082 |      56443.95 |           30.66 |
| Belgium        |              25 |           98 |       23237 |      41196.34 |           20.28 |
| Sweden         |               8 |           36 |       36083 |      38378.33 |           85.10 |
| Japan          |               8 |           19 |       26016 |      37416.37 |          116.56 |
| Norway         |              10 |           36 |       19336 |      36165.44 |           33.77 |
| Portugal       |              19 |           57 |       16122 |      33439.89 |           22.87 |
| Finland        |              12 |           41 |       10704 |      22546.08 |           32.91 |
| Singapore      |               1 |            7 |        5241 |      21279.29 |           95.85 |
+----------------+-----------------+--------------+-------------+---------------+-----------------+
15 rows in set (3.50 sec)

mysql> -- RFM: Recency, Frequency, Monetary Analysis
mysql> WITH customer_rfm AS (
    ->     SELECT
    ->         CustomerID,
    ->         DATEDIFF((SELECT MAX(invoice_date_clean) FROM transactions),
    ->                   MAX(invoice_date_clean)) as recency_days,
    ->         COUNT(DISTINCT InvoiceNo) as frequency,
    ->         ROUND(SUM(Quantity * UnitPrice), 2) as monetary_value
    ->     FROM transactions
    ->     WHERE invoice_date_clean IS NOT NULL
    ->       AND Quantity > 0
    ->       AND UnitPrice > 0
    ->       AND CustomerID IS NOT NULL
    ->     GROUP BY CustomerID
    -> )
    -> SELECT
    ->     CASE
    ->         WHEN recency_days <= 30 AND frequency >= 10 AND monetary_value >= 5000 THEN 'VIP Customer'
    ->         WHEN recency_days <= 90 AND frequency >= 5 AND monetary_value >= 2000 THEN 'Loyal Customer'
    ->         WHEN recency_days > 180 THEN 'At Risk/Churned'
    ->         ELSE 'Regular Customer'
    ->     END as customer_segment,
    ->     COUNT(*) as customer_count,
    ->     ROUND(AVG(monetary_value), 2) as avg_lifetime_value,
    ->     ROUND(AVG(frequency), 1) as avg_purchase_frequency
    -> FROM customer_rfm
    -> GROUP BY customer_segment
    -> ORDER BY customer_count DESC;
+------------------+----------------+--------------------+------------------------+
| customer_segment | customer_count | avg_lifetime_value | avg_purchase_frequency |
+------------------+----------------+--------------------+------------------------+
| Regular Customer |           2774 |             946.17 |                    2.7 |
| At Risk/Churned  |            858 |             647.47 |                    1.5 |
| Loyal Customer   |            520 |            3831.96 |                    9.1 |
| VIP Customer     |            186 |           20099.86 |                   26.2 |
+------------------+----------------+--------------------+------------------------+
4 rows in set (2.50 sec)

mysql> -- Negative Quantity = Returns/Cancellations
mysql> SELECT
    ->     COUNT(*) as return_transactions,
    ->     SUM(ABS(Quantity)) as total_returned_items,
    ->     ROUND(SUM(ABS(Quantity * UnitPrice)), 2) as revenue_lost,
    ->     ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions), 2) as return_percentage
    -> FROM transactions
    -> WHERE Quantity < 0;
+---------------------+----------------------+--------------+-------------------+
| return_transactions | total_returned_items | revenue_lost | return_percentage |
+---------------------+----------------------+--------------+-------------------+
|               10624 |               484531 |    896812.49 |              1.96 |
+---------------------+----------------------+--------------+-------------------+
1 row in set (0.82 sec)

mysql> -- Peak Shopping Hours
mysql> SELECT
    ->     HOUR(invoice_date_clean) as hour_of_day,
    ->     COUNT(DISTINCT InvoiceNo) as total_orders,
    ->     ROUND(SUM(Quantity * UnitPrice), 2) as hourly_revenue
    -> FROM transactions
    -> WHERE invoice_date_clean IS NOT NULL
    ->   AND Quantity > 0
    ->   AND UnitPrice > 0
    -> GROUP BY HOUR(invoice_date_clean)
    -> ORDER BY hour_of_day;
+-------------+--------------+----------------+
| hour_of_day | total_orders | hourly_revenue |
+-------------+--------------+----------------+
|           6 |            1 |           4.25 |
|           7 |           29 |       31059.21 |
|           8 |          566 |      283868.52 |
|           9 |         1484 |      990267.82 |
|          10 |         2361 |     1446742.70 |
|          11 |         2396 |     1239954.44 |
|          12 |         3220 |     1444245.88 |
|          13 |         2753 |     1265736.30 |
|          14 |         2457 |     1181812.37 |
|          15 |         2336 |     1352972.18 |
|          16 |         1335 |      754006.56 |
|          17 |          667 |      461603.49 |
|          18 |          192 |      144813.05 |
|          19 |          146 |       50665.01 |
|          20 |           18 |       18932.76 |
+-------------+--------------+----------------+
15 rows in set (2.59 sec)

mysql> -- Items Per Order Analysis
mysql> SELECT
    ->     AVG(items_per_order) as avg_items_per_basket,
    ->     AVG(order_value) as avg_basket_value,
    ->     MAX(items_per_order) as max_items_in_order,
    ->     MAX(order_value) as largest_order_value
    -> FROM (
    ->     SELECT
    ->         InvoiceNo,
    ->         SUM(Quantity) as items_per_order,
    ->         SUM(Quantity * UnitPrice) as order_value
    ->     FROM transactions
    ->     WHERE Quantity > 0 AND UnitPrice > 0
    ->     GROUP BY InvoiceNo
    -> ) as order_summary;
+----------------------+------------------+--------------------+---------------------+
| avg_items_per_basket | avg_basket_value | max_items_in_order | largest_order_value |
+----------------------+------------------+--------------------+---------------------+
|             279.9786 |       534.403033 |              80995 |           168469.60 |
+----------------------+------------------+--------------------+---------------------+
1 row in set (2.08 sec)

mysql> -- High Value Customers
mysql> SELECT
    ->     CustomerID,
    ->     COUNT(DISTINCT InvoiceNo) as total_orders,
    ->     SUM(Quantity) as total_items_purchased,
    ->     ROUND(SUM(Quantity * UnitPrice), 2) as lifetime_value,
    ->     ROUND(AVG(Quantity * UnitPrice), 2) as avg_order_value,
    ->     MIN(invoice_date_clean) as first_purchase,
    ->     MAX(invoice_date_clean) as last_purchase,
    ->     DATEDIFF(MAX(invoice_date_clean), MIN(invoice_date_clean)) as customer_tenure_days
    -> FROM transactions
    -> WHERE invoice_date_clean IS NOT NULL
    ->   AND Quantity > 0
    ->   AND UnitPrice > 0
    ->   AND CustomerID IS NOT NULL
    -> GROUP BY CustomerID
    -> ORDER BY lifetime_value DESC
    -> LIMIT 20;
+------------+--------------+-----------------------+----------------+-----------------+---------------------+---------------------+----------------------+
| CustomerID | total_orders | total_items_purchased | lifetime_value | avg_order_value | first_purchase      | last_purchase       | customer_tenure_days |
+------------+--------------+-----------------------+----------------+-----------------+---------------------+---------------------+----------------------+
|      14646 |           73 |                196915 |      280206.02 |          134.97 | 2010-12-20 10:09:00 | 2011-12-08 12:12:00 |                  353 |
|      18102 |           60 |                 64124 |      259657.30 |          602.45 | 2010-12-07 16:42:00 | 2011-12-09 11:50:00 |                  367 |
|      17450 |           46 |                 69993 |      194550.79 |          577.30 | 2010-12-07 09:23:00 | 2011-12-01 13:29:00 |                  359 |
|      16446 |            2 |                 80997 |      168472.50 |        56157.50 | 2011-05-18 09:52:00 | 2011-12-09 09:15:00 |                  205 |
|      14911 |          201 |                 80265 |      143825.06 |           25.34 | 2010-12-01 14:05:00 | 2011-12-08 15:54:00 |                  372 |
|      12415 |           21 |                 77374 |      124914.53 |          174.95 | 2011-01-06 11:12:00 | 2011-11-15 14:22:00 |                  313 |
|      14156 |           55 |                 57885 |      117379.63 |           83.84 | 2010-12-03 11:48:00 | 2011-11-30 10:54:00 |                  362 |
|      17511 |           31 |                 64549 |       91062.38 |           94.56 | 2010-12-01 10:19:00 | 2011-12-07 10:12:00 |                  371 |
|      16029 |           63 |                 40208 |       81024.84 |          334.81 | 2010-12-01 09:57:00 | 2011-11-01 10:27:00 |                  335 |
|      12346 |            1 |                 74215 |       77183.60 |        77183.60 | 2011-01-18 10:01:00 | 2011-01-18 10:01:00 |                    0 |
|      16684 |           28 |                 50255 |       66653.56 |          240.63 | 2010-12-16 17:34:00 | 2011-12-05 14:06:00 |                  354 |
|      14096 |           17 |                 16352 |       65164.79 |           12.75 | 2011-08-30 10:49:00 | 2011-12-05 17:17:00 |                   97 |
|      13694 |           50 |                 63312 |       65039.62 |          114.51 | 2010-12-01 12:12:00 | 2011-12-06 09:32:00 |                  370 |
|      15311 |           91 |                 38194 |       60767.90 |           25.54 | 2010-12-01 09:41:00 | 2011-12-09 12:00:00 |                  373 |
|      13089 |           97 |                 31070 |       58825.83 |           32.36 | 2010-12-05 10:27:00 | 2011-12-07 09:02:00 |                  367 |
|      17949 |           45 |                 30546 |       58510.48 |          835.86 | 2010-12-03 13:12:00 | 2011-12-08 18:46:00 |                  370 |
|      15769 |           26 |                 29672 |       56252.72 |          432.71 | 2010-12-03 15:16:00 | 2011-12-02 13:52:00 |                  364 |
|      15061 |           48 |                 28920 |       54534.14 |          135.32 | 2010-12-02 15:19:00 | 2011-12-06 12:06:00 |                  369 |
|      14298 |           44 |                 58343 |       51527.30 |           31.48 | 2010-12-14 12:59:00 | 2011-12-01 13:12:00 |                  352 |
|      14088 |           13 |                 12665 |       50491.81 |           85.72 | 2011-01-21 13:07:00 | 2011-11-29 16:16:00 |                  312 |
+------------+--------------+-----------------------+----------------+-----------------+---------------------+---------------------+----------------------+
20 rows in set (2.04 sec)

mysql> -- Customer Loyalty: One-Time vs Repeat Buyers
mysql> SELECT
    ->     CASE
    ->         WHEN total_orders = 1 THEN 'One-Time Buyer (Acquisition Focus)'
    ->         ELSE 'Repeat Buyer (Retention Focus)'
    ->     END as loyalty_group,
    ->     COUNT(CustomerID) as total_customers,
    ->     ROUND(AVG(lifetime_value), 2) as avg_ltv_group
    -> FROM (
    ->     SELECT
    ->         CustomerID,
    ->         COUNT(DISTINCT InvoiceNo) as total_orders,
    ->         SUM(Quantity * UnitPrice) as lifetime_value
    ->     FROM transactions
    ->     WHERE CustomerID IS NOT NULL
    ->       AND Quantity > 0
    ->       AND UnitPrice > 0
    ->     GROUP BY CustomerID
    -> ) as customer_orders_summary
    -> GROUP BY loyalty_group;
+------------------------------------+-----------------+---------------+
| loyalty_group                      | total_customers | avg_ltv_group |
+------------------------------------+-----------------+---------------+
| One-Time Buyer (Acquisition Focus) |            1493 |        412.80 |
| Repeat Buyer (Retention Focus)     |            2845 |       2915.68 |
+------------------------------------+-----------------+---------------+
2 rows in set (1.59 sec)

mysql> exit