-- Query 1 - What kind of customers are the most profitable for the rental store?
WITH customer_segment AS (
  SELECT 
    c.customer_id, 
    CASE
      WHEN COUNT(DISTINCT p.payment_id) >= 40 THEN 'Frequent'
      WHEN COUNT(DISTINCT p.payment_id) >= 20 THEN 'Regular'
      ELSE 'Once in a while'
    END AS customer_segment
  FROM 
    customer c
    JOIN payment p ON c.customer_id = p.customer_id
  GROUP BY 
    c.customer_id
)
SELECT 
  cs.customer_segment, 
  COUNT(cs.customer_id) AS customer_count, 
  SUM(p.amount) AS total_revenue
FROM 
  customer_segment cs
  JOIN payment p ON cs.customer_id = p.customer_id
GROUP BY 
  cs.customer_segment
ORDER BY 
  total_revenue DESC;



-- Query 2 - How can we use the data to recommend customers new movies, and how does this effect us as a seller?
SELECT 
  g.name AS genre, 
  COUNT(DISTINCT c.customer_id) AS customer_count, 
  COUNT(r.rental_id) AS rental_count
FROM 
  customer c
  JOIN rental r ON c.customer_id = r.customer_id
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film_category fc ON i.film_id = fc.film_id
  JOIN category g ON fc.category_id = g.category_id
GROUP BY 
  g.category_id
HAVING 
  COUNT(DISTINCT c.customer_id) > 3 
ORDER BY 
  rental_count DESC;



-- Query 3 - Enlist the top 10 movies that are rented the most of all time, how does it compares to the average rental rate of all the movies in the data?
WITH movie_rental_count AS (
  SELECT
    f.title,
    COUNT(r.rental_id) AS rental_count
  FROM
    film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
  GROUP BY f.title
)
SELECT 
  title, 
  rental_count,
  rental_count / AVG(rental_count) OVER() AS avg_frequency_ratio
FROM 
  movie_rental_count
ORDER BY 
  rental_count DESC
LIMIT 10;



-- Query 4 - Which actors have appeared most in each category of movies?
WITH actor_category AS (
  SELECT 
    a.actor_id,
    c.name AS category_name,
    a.first_name || ' ' || a.last_name AS actor_name,
    COUNT(*) AS no_of_movies
  FROM 
    film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
  GROUP BY 
    c.name, a.actor_id, a.first_name, a.last_name
),
top_category AS (
  SELECT 
    category_name, 
    actor_name, 
    no_of_movies,
    ROW_NUMBER() OVER (
      PARTITION BY category_name 
      ORDER BY no_of_movies DESC 
    ) AS actor_rank
  FROM 
    actor_category 
)
SELECT 
  actor_name, 
  category_name, 
  no_of_movies
FROM 
  top_category
WHERE 
  actor_rank = 1;
