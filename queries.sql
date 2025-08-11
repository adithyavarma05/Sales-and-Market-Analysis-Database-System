/*
Generate a report of individual product sales aggregated on a "monthly basis"
at the product code level for Croma India customer for FY-2021.

The report should have the following fields:

1.  Month
2.  Product Name
3.  Variant
4.  Sold Quantity
5.  Gross Price Per Item
6.  Gross Price Total
*/

-- a. first grab customer codes for Croma india
	SELECT * FROM dim_customer WHERE customer like "%croma%" AND market="india";

-- b. Get all the sales transaction data from fact_sales_monthly table for that customer(croma: 90002002) in the fiscal_year 2021
	SELECT * FROM fact_sales_monthly 
	WHERE 
            customer_code=90002002 AND
            YEAR(DATE_ADD(date, INTERVAL 4 MONTH))=2021 
	ORDER BY date asc
	LIMIT 100000;

-- c. create a function 'get_fiscal_year' to get fiscal year by passing the date

	DELIMITER $$

	CREATE FUNCTION get_fiscal_year(calendar_date DATE) 
	RETURNS INT
	DETERMINISTIC
	BEGIN
		DECLARE fiscal_year INT;
		SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
		RETURN fiscal_year;
	END$$

	DELIMITER ;

-- d. Replacing the function created in the step:b
	SELECT * FROM fact_sales_monthly 
	WHERE 
            customer_code=90002002 AND
            get_fiscal_year(date)=2021 
	ORDER BY date asc
	LIMIT 100000;
    
/*
Generate a report of monthly product transactions aggregated
at the product code level for all products.
*/

-- a. Perform joins to pull product information
	SELECT s.date, s.product_code, p.product, p.variant, s.sold_quantity 
	FROM fact_sales_monthly s
	JOIN dim_product p
        ON s.product_code=p.product_code
	WHERE 
            customer_code=90002002 AND 
    	    get_fiscal_year(date)=2021     
	LIMIT 1000000;

-- b. Performing join with 'fact_gross_price' table with the above query and generating required fields
	SELECT 
    	    s.date, 
            s.product_code, 
            p.product, 
            p.variant, 
            s.sold_quantity, 
            g.gross_price,
            ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total
	FROM fact_sales_monthly s
	JOIN dim_product p
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
            ON g.fiscal_year=get_fiscal_year(s.date)
    	AND g.product_code=s.product_code
	WHERE 
    	    customer_code=90002002 AND 
            get_fiscal_year(s.date)=2021     
	LIMIT 1000000;

/* 
Generate a report of total sales amount aggregated 
on a monthly basis at the product code level for all products.

*/

-- Generate monthly gross sales report for Croma India for all the years
	SELECT 
            s.date, 
    	    SUM(ROUND(s.sold_quantity*g.gross_price,2)) as monthly_sales
	FROM fact_sales_monthly s
	JOIN fact_gross_price g
        ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
	WHERE 
             customer_code=90002002
	GROUP BY date;
    
/*
Create a stored procedure that generates a monthly gross sales report 
for any customer.

The stored procedure should:
- Accept a customer code as input.
- Aggregate sales data on a monthly basis.
- Return month, product details, sold quantity, gross price per item, and total gross sales.
*/    
    
    DELIMITER $$

	CREATE PROCEDURE get_monthly_gross_sales_for_customer(
		IN in_customer_codes TEXT
	)
	BEGIN
		SELECT 
			s.`date` AS Month,
			SUM(ROUND(s.sold_quantity * g.gross_price, 2)) AS monthly_sales
		FROM fact_sales_monthly s
		JOIN fact_gross_price g
			ON g.fiscal_year = get_fiscal_year(s.`date`)
		   AND g.product_code = s.product_code
		WHERE FIND_IN_SET(s.customer_code, in_customer_codes) > 0
		GROUP BY s.`date`
		ORDER BY s.`date` DESC;
	END$$

	DELIMITER ;    
    
/*
Create a stored procedure that determines a market badge 
based on total sold quantity.

The stored procedure should:
- Accept a market name as input.
- Calculate the total sold quantity for that market.
- Return "Gold" if total sold quantity > 5 million, otherwise return "Silver".
*/

DELIMITER $$

	CREATE PROCEDURE get_market_badge(
		IN in_market VARCHAR(45),
		IN in_fiscal_year INT,
		OUT out_level VARCHAR(45)
	)
	BEGIN
		DECLARE qty BIGINT DEFAULT 0;

		-- Default to India if no market given
		IF in_market IS NULL OR in_market = '' THEN
			SET in_market = 'India';
		END IF;

		-- Calculate total sold quantity for the market & fiscal year
		SELECT SUM(fsm.sold_quantity)
		INTO qty
		FROM fact_sales_monthly fsm
		JOIN dim_customer dc 
			ON fsm.customer_code = dc.customer_code
		WHERE dc.market = in_market
		  AND YEAR(DATE_ADD(fsm.`date`, INTERVAL 4 MONTH)) = in_fiscal_year;

		-- Determine market badge
		IF qty > 5000000 THEN
			SET out_level = 'Gold';
		ELSE
			SET out_level = 'Silver';
		END IF;

	END$$

	DELIMITER ;
    

/*
Update the Croma detailed sales report to include pre-invoice deductions.
*/

	SELECT 
    	   s.date, 
           s.product_code, 
           p.product, 
	   p.variant, 
           s.sold_quantity, 
           g.gross_price as gross_price_per_item,
           ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
           pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_product p
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
    	    ON g.fiscal_year=get_fiscal_year(s.date)
    	    AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
            ON pre.customer_code = s.customer_code AND
            pre.fiscal_year=get_fiscal_year(s.date)
	WHERE 
	    s.customer_code=90002002 AND 
    	    get_fiscal_year(s.date)=2021     
	LIMIT 1000000;
    
/*
Generate the detailed sales report for all customers,
including pre-invoice deductions.
*/

	SELECT 
    	   s.date, 
           s.product_code, 
           p.product, 
	   p.variant, 
           s.sold_quantity, 
           g.gross_price as gross_price_per_item,
           ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
           pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_product p
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
    	    ON g.fiscal_year=get_fiscal_year(s.date)
    	    AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
            ON pre.customer_code = s.customer_code AND
            pre.fiscal_year=get_fiscal_year(s.date)
	WHERE 
    	    get_fiscal_year(s.date)=2021     
	LIMIT 1000000;
    
/*
Calculate the net invoice sales amount using Common Table Expressions (CTEs)
*/

	WITH cte1 AS (
		SELECT 
    		    s.date, 
    		    s.customer_code,
    		    s.product_code, 
                    p.product, p.variant, 
                    s.sold_quantity, 
                    g.gross_price as gross_price_per_item,
                    ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
                    pre.pre_invoice_discount_pct
		FROM fact_sales_monthly s
		JOIN dim_product p
        		ON s.product_code=p.product_code
		JOIN fact_gross_price g
    			ON g.fiscal_year=s.fiscal_year
    			AND g.product_code=s.product_code
		JOIN fact_pre_invoice_deductions as pre
        		ON pre.customer_code = s.customer_code AND
    			pre.fiscal_year=s.fiscal_year
		WHERE 
    			s.fiscal_year=2021) 
	SELECT 
      	    *, 
    	    (gross_price_total-pre_invoice_discount_pct*gross_price_total) as net_invoice_sales
	FROM cte1
	LIMIT 1500000;
    
/*
Create a view named sales_preinv_discount  and access pre-invoice discount data 
as a virtual table for easier querying and analysis without physically storing 
the results.
*/

	CREATE  VIEW `sales_preinv_discount` AS
	SELECT 
    	    s.date, 
            s.fiscal_year,
            s.customer_code,
            c.market,
            s.product_code, 
            p.product, 
            p.variant, 
            s.sold_quantity, 
            g.gross_price as gross_price_per_item,
            ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
            pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_customer c 
		ON s.customer_code = c.customer_code
	JOIN dim_product p
        	ON s.product_code=p.product_code
	JOIN fact_gross_price g
    		ON g.fiscal_year=s.fiscal_year
    		AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
        	ON pre.customer_code = s.customer_code AND
    		pre.fiscal_year=s.fiscal_year
            
/*
Now generate net_invoice_sales using the above created view 
"sales_preinv_discount" as stored procedure
*/

	DELIMITER $$

	CREATE PROCEDURE get_sales()
	BEGIN
		SELECT *,
			   ROUND(gross_price_total - (pre_invoice_discount_pct * gross_price_total), 2) AS net_invoice_sales
		FROM sales_preinv_discount;
	END$$

	DELIMITER ;
        
/*
Create a view for post invoice deductions: `sales_postinv_discount`
*/

	CREATE VIEW `sales_postinv_discount` AS
	SELECT 
    	    s.date, s.fiscal_year,
            s.customer_code, s.market,
            s.product_code, s.product, s.variant,
            s.sold_quantity, s.gross_price_total,
            s.pre_invoice_discount_pct,
            (s.gross_price_total-s.pre_invoice_discount_pct*s.gross_price_total) as net_invoice_sales,
            (po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct
	FROM sales_preinv_discount s
	JOIN fact_post_invoice_deductions po
		ON po.customer_code = s.customer_code AND
   		po.product_code = s.product_code AND
   		po.date = s.date;
        
/*
Create a report for net sales
*/

	SELECT 
            *, 
    	    net_invoice_sales*(1-post_invoice_discount_pct) as net_sales
	FROM gdb0041.sales_postinv_discount;

-- Finally creating the view `net_sales` which inbuiltly use/include all the previous created view and gives the final result
	CREATE VIEW `net_sales` AS
	SELECT 
            *, 
    	    net_invoice_sales*(1-post_invoice_discount_pct) as net_sales
	FROM sales_postinv_discount;

/*
Get top 5 market by net sales in fiscal year 2021
*/
	SELECT 
    	    market, 
            round(sum(net_sales)/1000000,2) as net_sales_mln
	FROM gdb0041.net_sales
	where fiscal_year=2021
	group by market
	order by net_sales_mln desc
	limit 5

/*
Create Stored proc to get top n markets by net sales for a given year
*/

	DELIMITER $$

	CREATE PROCEDURE `get_top_n_markets_by_net_sales`(
		IN in_fiscal_year INT,
		IN in_top_n INT
	)
	BEGIN
		SELECT 
			market, 
			ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
		FROM net_sales
		WHERE fiscal_year = in_fiscal_year
		GROUP BY market
		ORDER BY net_sales_mln DESC
		LIMIT in_top_n;
	END$$

	DELIMITER ;
    
/*
Create stored procedure that takes market, fiscal_year and top n as an input 
and returns top n customers by net sales in that given fiscal year and market.
*/

	DELIMITER $$

	CREATE PROCEDURE `get_top_n_customers_by_net_sales`(
		IN in_market VARCHAR(45),
		IN in_fiscal_year INT,
		IN in_top_n INT
	)
	BEGIN
		SELECT 
			customer, 
			ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
		FROM net_sales s
		JOIN dim_customer c
			ON s.customer_code = c.customer_code
		WHERE 
			s.fiscal_year = in_fiscal_year 
			AND s.market = in_market
		GROUP BY customer
		ORDER BY net_sales_mln DESC
		LIMIT in_top_n;
	END$$

	DELIMITER ;
    
/*
Find out customer wise net sales percentage contribution 
*/

	with cte1 as (
		select 
                    customer, 
                    round(sum(net_sales)/1000000,2) as net_sales_mln
        	from net_sales s
        	join dim_customer c
                    on s.customer_code=c.customer_code
        	where s.fiscal_year=2021
        	group by customer)
	select 
            *,
            net_sales_mln*100/sum(net_sales_mln) over() as pct_net_sales
	from cte1
	order by net_sales_mln desc
    
/*
Find customer wise net sales distibution per region for FY 2021.
*/

	with cte1 as (
		select 
        	    c.customer,
                    c.region,
                    round(sum(net_sales)/1000000,2) as net_sales_mln
                from gdb0041.net_sales n
                join dim_customer c
                    on n.customer_code=c.customer_code
		where fiscal_year=2021
		group by c.customer, c.region)
	select
             *,
             net_sales_mln*100/sum(net_sales_mln) over (partition by region) as pct_share_region
	from cte1
	order by region, pct_share_region desc

/*
Find out top 3 products from each division by total quantity sold in a given year.
*/

	with cte1 as 
		(select
                     p.division,
                     p.product,
                     sum(sold_quantity) as total_qty
                from fact_sales_monthly s
                join dim_product p
                      on p.product_code=s.product_code
                where fiscal_year=2021
                group by p.product),
           cte2 as 
	        (select 
                     *,
                     dense_rank() over (partition by division order by total_qty desc) as drnk
                from cte1)
	select * from cte2 where drnk<=3
   
/*
Creating stored procedure for the above query
*/

	DELIMITER $$
	CREATE PROCEDURE `get_top_n_products_per_division_by_qty_sold`(
        	in_fiscal_year INT,
    		in_top_n INT
	)
	BEGIN
	     with cte1 as (
		   select
                       p.division,
                       p.product,
                       sum(sold_quantity) as total_qty
                   from fact_sales_monthly s
                   join dim_product p
                       on p.product_code=s.product_code
                   where fiscal_year=in_fiscal_year
                   group by p.product),            
             cte2 as (
		   select 
                        *,
                        dense_rank() over (partition by division order by total_qty desc) as drnk
                   from cte1)
	     select * from cte2 where drnk <= in_top_n;
	END
    DELIMITER ;