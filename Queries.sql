SELECT * FROM sales

SELECT * FROM menu

SELECT * FROM members

/* 1. What is the total amount each customer spent at the restaurant?*/

SELECT 
  sales.customer_id, 
  SUM(menu.price) AS total_sales
FROM sales
INNER JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC; 


/* 2. How many days has each customer visited the restaurant?*/
SELECT customer_id, COUNT(DISTINCT order_date) as visits 
FROM sales
GROUP BY customer_id


/* 3. What was the first item from the menu purchased by each customer?*/
WITH customer_order_cte AS(
SELECT customer_id, 
	order_date, 
	product_name,
	RANK() OVER( PARTITION BY customer_id ORDER BY order_date) as Rank

FROM sales as s INNER JOIN menu as m ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM customer_order_cte
WHERE Rank = 1

/* 4. What is the most purchased item on the menu and how many times was it purchased by all customers? */
SELECT TOP(1) product_name, COUNT(s.product_id) as No_of_times_purchased
FROM sales as s INNER JOIN menu as m ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY No_of_times_purchased DESC

/* 5. Which item was the most popular for each customer? */
SELECT customer_id, product_name, COUNT(s.product_id) as ordered,
	DENSE_RANK() OVER( PARTITION BY customer_id ORDER BY COUNT(s.product_id) DESC) AS DenseRank,
FROM sales as s INNER JOIN menu as m ON s.product_id = m.product_id
GROUP BY customer_id , product_name


/* 6. Which item was purchased first by the customer after they became a member? */
WITH first_order AS(
SELECT s.customer_id,
		order_date,
		product_id,
		join_date,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) as Rank
FROM sales as s RIGHT JOIN members as mem ON s.customer_id = mem.customer_id
WHERE order_date >= join_date
)
SELECT customer_id,
		order_date,
		product_name,
		join_date
FROM first_order as fo INNER JOIN menu as m ON fo.product_id = m.product_id 
WHERE Rank = 1

/* 7. Which item was purchased just before the customer became a member? */
WITH Last_order AS(
SELECT s.customer_id,
		order_date,
		product_id,
		join_date,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) as Rank
FROM sales as s Inner JOIN members as mem ON s.customer_id = mem.customer_id
WHERE order_date < join_date
)
SELECT customer_id,
		order_date,
		product_name,
		join_date
FROM Last_order as lo INNER JOIN menu as m ON lo.product_id = m.product_id 
WHERE Rank = 1

/*8.  What is the total items and amount spent for each member before they became a member? */
SELECT s.customer_id, SUM(price) as total_spent_amount, COUNT(*) as item_purchased  
FROM sales as s INNER JOIN members as mem 
	ON s.customer_id = mem.customer_id INNER JOIN menu as m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id


/* 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */

/* APPROACH 1 */
SELECT customer_id, 
	SUM(CASE WHEN m.product_id = 1 THEN price*20
	ELSE price*10 END) as points
FROM sales as s LEFT JOIN menu as m ON s.product_id = m.product_id
GROUP BY customer_id

/* APPROACH 2 */
WITH cte as(
SELECT *, 
	(CASE WHEN product_name = 'sushi'  THEN price*20
	ELSE price*10 END) as points
FROM menu
)

SELECT customer_id, SUM(c.points) as total_points
FROM sales as s LEFT JOIN cte as c ON s.product_id = c.product_id
GROUP BY customer_id

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January? */

WITH dates_cte AS(
	SELECT *, 
		DATEADD(DAY, 6, join_date) AS valid_date, 
		EOMONTH('2021-01-1') AS last_date
	FROM members
)

SELECT s.customer_id, 
		SUM( CASE 
				WHEN product_name = 'sushi' THEN price*20
				WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN price*20
				ELSE price*10 END) AS total_points

FROM dates_cte as d JOIN sales as s ON d.customer_id = s.customer_id JOIN menu as m ON s.product_id = m.product_id
WHERE order_date <= d.last_date
GROUP BY s.customer_id


