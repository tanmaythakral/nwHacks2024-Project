import datetime
import random

def randomized_date_between_10am_and_6pm():
    # Set the date range for 10 am to 6 pm
    start_time = datetime.time(10, 0)
    end_time = datetime.time(18, 0)

    # Get the current date
    current_date = datetime.date.today()

    # Combine the current date with a random time between 10 am and 6 pm
    random_time = datetime.datetime.combine(current_date, start_time) + \
                  datetime.timedelta(seconds=random.randint(0, (end_time.hour - start_time.hour) * 3600))

    return random_time

if __name__ == "__main__":
    # Example usage
    random_date = randomized_date_between_10am_and_6pm()
    print("Randomized Date and Time between 10 am and 6 pm:", random_date)
