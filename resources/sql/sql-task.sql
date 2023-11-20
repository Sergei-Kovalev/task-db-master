-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT model, fare_conditions,
count(*) AS fare_condition_count
FROM aircrafts_data
LEFT JOIN seats ON seats.aircraft_code = aircrafts_data.aircraft_code
GROUP BY model, fare_conditions;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT model,
count(*) AS total_seats
FROM aircrafts_data
LEFT JOIN seats ON seats.aircraft_code = aircrafts_data.aircraft_code
GROUP BY model
ORDER BY total_seats DESC
LIMIT 3;

-- 3. Найти все рейсы, которые задерживались более 2 часов

SELECT flight_no,
actual_arrival - scheduled_arrival AS delay
FROM flights
WHERE actual_arrival - scheduled_arrival > '2 hours'

-- 4. Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных

SELECT bookings.book_date, tickets.ticket_no, passenger_name, contact_data, flights.flight_no, boarding_passes.seat_no, seats.fare_conditions
FROM tickets
LEFT JOIN bookings ON tickets.book_ref = bookings.book_ref
LEFT JOIN boarding_passes ON tickets.ticket_no = boarding_passes.ticket_no
LEFT JOIN flights ON boarding_passes.flight_id = flights.flight_id
LEFT JOIN seats ON boarding_passes.seat_no = seats.seat_no AND flights.aircraft_code = seats.aircraft_code
WHERE seats.fare_conditions = 'Business'
ORDER BY bookings.book_date DESC
limit 10

-- 5. Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')

SELECT flight_no
FROM (
	SELECT flights.flight_no,
	count(
		CASE
			WHEN ticket_flights.fare_conditions = 'Business' THEN 1
		END) as business_tickets_count
	FROM flights
	LEFT JOIN ticket_flights ON ticket_flights.flight_id = flights.flight_id
-- 	WHERE ticket_flights.fare_conditions IS NOT NULL -- удалит все рейсы на которые места вообще не приобретались.
	GROUP BY (flights.flight_no)
	ORDER BY flights.flight_no
)
flight_no
WHERE business_tickets_count = 0


-- 6. Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой

SELECT airports_data.airport_name, airports_data.city, flights.status
FROM airports_data
INNER JOIN flights ON flights.departure_airport = airports_data.airport_code OR flights.arrival_airport = airports_data.airport_code
WHERE flights.status = 'Delayed'

-- 7.
