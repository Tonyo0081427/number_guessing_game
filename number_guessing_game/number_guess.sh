#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c"

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read USERNAME

USERNAME_SQL=$(echo "$USERNAME" | sed "s/'/''/g")

USER_INFO=$($PSQL "SELECT user_id, COUNT(game_id), MIN(number_of_guesses) FROM users LEFT JOIN games USING(user_id) WHERE username='$USERNAME_SQL' GROUP BY user_id;")

if [[ -z $USER_INFO ]]
then
  USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME_SQL') RETURNING user_id;" | head -n 1)
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS="|" read -r USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
read GUESS

GUESSES=0

while [[ $GUESS != $SECRET_NUMBER ]]
do
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    ((GUESSES++))

    if [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi

  read GUESS
done

((GUESSES++))

echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $GUESSES);"