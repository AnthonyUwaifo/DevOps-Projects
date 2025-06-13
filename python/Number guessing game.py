import random

while True:
    trial = 3
    count = 0
    hidden = random.randint(0, 9)
    print("Number Guessing Game \n \n")
    print("A random number has been generated! \n")

    while trial > 0:
        try:
            guess = int(input("Guess the number from 0 to 9: "))
        except ValueError:
            print("Invalid input. Please enter an integer between 0 and 9.")
            continue

        count += 1
        trial -= 1

        if guess == hidden:
            print(f"Hurray!!! You won in {count} {'try' if count == 1 else 'tries'}. \n")
            break
        elif trial > 0:
            print("Sorry, better luck next time.")
            print(f"You have {trial} {'try' if trial == 1 else 'tries'} left. \n")
        else:
            print("Game Over!")
            print(f"The number was {hidden}.\n")

    again = input("Type 'Y' to play again and 'N' to quit: ")
    if again.lower() != 'y':
        print("Thanks for playing! Bye!")
        break
    print("\n")
