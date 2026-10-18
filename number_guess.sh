#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Escape single quotes for SQL
SAFE_USERNAME=$(printf '%s' "$USERNAME" | sed "s/'/''/g")

USER_INFO=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$SAFE_USERNAME'")

if [[ -z "$USER_INFO" ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$SAFE_USERNAME')" > /dev/null
else
  IFS='|' read -r DB_USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $DB_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"

while read -r GUESS; do
  if [[ ! "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    $PSQL "UPDATE users
      SET games_played = games_played + 1,
          best_game = CASE
            WHEN best_game IS NULL OR $NUMBER_OF_GUESSES < best_game
            THEN $NUMBER_OF_GUESSES
            ELSE best_game
          END
      WHERE username='$SAFE_USERNAME'" > /dev/null

    break
  fi
done
