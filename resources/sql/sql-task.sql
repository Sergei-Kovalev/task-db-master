-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT model, fare_conditions,
count(*) AS fare_condition_count
FROM aircrafts AS a
LEFT JOIN seats AS s ON s.aircraft_code = a.aircraft_code
GROUP BY model, fare_conditions;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT model,
count(*) AS total_seats
FROM aircrafts AS a
LEFT JOIN seats AS s ON s.aircraft_code = a.aircraft_code
GROUP BY model
ORDER BY total_seats DESC
LIMIT 3;

-- 3. Найти все рейсы, которые задерживались более 2 часов

SELECT flight_no,
actual_arrival - scheduled_arrival AS delay
FROM flights
WHERE actual_arrival - scheduled_arrival > '2 hours'

-- 4. Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных

SELECT b.book_date, t.ticket_no, passenger_name, contact_data, f.flight_no, bp.seat_no, s.fare_conditions
FROM tickets AS t
LEFT JOIN bookings AS b ON t.book_ref = b.book_ref
LEFT JOIN boarding_passes AS bp ON t.ticket_no = bp.ticket_no
LEFT JOIN flights AS f ON bp.flight_id = f.flight_id
LEFT JOIN seats AS s ON bp.seat_no = s.seat_no AND f.aircraft_code = s.aircraft_code
WHERE s.fare_conditions = 'Business'
ORDER BY b.book_date DESC
limit 10

-- 5. Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')

SELECT flight_no
FROM (
	SELECT f.flight_no,
	count(
		CASE
			WHEN tf.fare_conditions = 'Business' THEN 1
		END) as business_tickets_count
	FROM flights AS f
	LEFT JOIN ticket_flights AS tf ON tf.flight_id = f.flight_id
-- 	WHERE ticket_flights.fare_conditions IS NOT NULL -- удалит все рейсы на которые места вообще не приобретались.
	GROUP BY f.flight_no
	ORDER BY f.flight_no
)
flight_no
WHERE business_tickets_count = 0


-- 6. Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой

SELECT a.airport_name, a.city, f.status
FROM airports AS a
INNER JOIN flights AS f ON f.departure_airport = a.airport_code OR f.arrival_airport = a.airport_code
WHERE f.status = 'Delayed'

-- 7. Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта,
-- отсортированный по убыванию количества рейсов

SELECT a.airport_name,
count(*) AS flights_count
FROM airports AS a
LEFT JOIN flights AS f ON a.airport_code = f.departure_airport
GROUP BY a.airport_name
ORDER BY flights_count DESC

-- 8. Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено
-- и новое время прибытия (actual_arrival) не совпадает с запланированным

-- выводит все рейсы с измененным временем, отдельно с каждым изменением
SELECT f.flight_no, f.scheduled_arrival, f.actual_arrival
FROM flights as f
WHERE f.actual_arrival IS NOT NULL AND f.actual_arrival != f.scheduled_arrival

-- выводит только названия рейсов, у которых хотя бы раз план не совпал с фактом.
SELECT f.flight_no
FROM flights as f
WHERE f.actual_arrival IS NOT NULL AND f.actual_arrival != f.scheduled_arrival
GROUP BY f.flight_no

-- 9. Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам

SELECT a.aircraft_code, a.model, s.seat_no
FROM aircrafts AS a
LEFT JOIN seats as s ON a.aircraft_code = s.aircraft_code
WHERE a.model = 'Аэробус A321-200'
ORDER BY s.seat_no

-- 10. Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

SELECT a.airport_code, a.airport_name, a.city
FROM (SELECT city,
count(*) as airports_count
FROM airports
GROUP BY city) as ac
LEFT JOIN airports as a ON ac.city = a.city
WHERE ac.airports_count > 1

-- 11. Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований

-- PS: сравниваются суммы стоимостей всех билетов одного пассажира из БД со средним значением у всех пассажиров

SELECT *
FROM (
	SELECT passenger_name, SUM(amount) as counter
	FROM ticket_flights AS tf
	LEFT JOIN tickets AS t ON tf.ticket_no = t.ticket_no
	GROUP BY passenger_name
) AS all_passengers_and_orders_price
WHERE counter > (
	SELECT AVG(average_orders)
	FROM (
		SELECT passenger_name, SUM(amount) as average_orders
		FROM ticket_flights AS tf
		LEFT JOIN tickets AS t ON tf.ticket_no = t.ticket_no
		GROUP BY passenger_name
	) AS average_orders_price
)

-- 12. Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

SELECT f.flight_no, MIN(f.scheduled_departure) as nearest_departure_time
FROM flights AS f
WHERE f.departure_airport = (
	SELECT a.airport_code
	FROM airports AS a
	WHERE a.city = 'Екатеринбург'
)
AND f.arrival_airport IN (
	SELECT a.airport_code
 	FROM airports AS a
 	WHERE a.city = 'Москва'
)
AND f.status IN ('On Time', 'Scheduled', 'Delayed')
GROUP BY f.flight_no

-- 13. Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)

SELECT *
FROM ticket_flights AS tf
WHERE tf.amount = (
	SELECT MIN(amount)
	FROM ticket_flights
)
OR tf.amount = (
	SELECT MAX(amount)
	FROM ticket_flights
)