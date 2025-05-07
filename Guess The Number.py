import random
trial = 3

while True:

    play_again = "y"
    count = 0
    hidden = random.randint(0, 9)
    while trial > 0:
        trial -= 1
        count += 1

        print("Guess a number from 0 to 9. \n")
        guess = input(": ")
        guess = int(guess)
        if guess == hidden and count == 1:
            print(f"Hurray!!! You won in {count} try.")
            break
        elif guess == hidden:
            print(f"Hurray!!! You won in {count} tries.")
            break
        elif guess != hidden and trial == 1:
            print("Sorry, better luck next time." f"\nYou have {trial} try left. \n")
            continue
        elif guess != hidden and trial == 0:
            print("Game Over!" f"\nYou have {trial} tries left." f"\nThe number is {hidden}. \n")
            continue
        elif guess != hidden:
            print("Sorry, better luck next time.")
            print(f"You have {trial} tries left.")
            continue
    if guess == hidden or trial == 0:
        print("Type 'Y' to play again and 'N' to quit.")
        again = input(": ")
        if play_again == again.upper() or play_again == again.lower():
            trial = 3
            print("\n")
            continue
        else:
            print("Thanks for playing! Bye!")
            break