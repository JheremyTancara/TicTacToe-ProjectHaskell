module TicTacToe where

import Data.List ( intercalate )
import Data.Char ( ord, toUpper )
import Data.Time.Clock.POSIX ( getPOSIXTime )

main = do
  putStrLn $ replicate 20 '\n'
  putStrLn "\nWelcome to tic-tac-toe!\n"
  putStrLn "To enter a move, type 'LN' where L is an uppercase letter signifying the column name and N is a number 0-9 signifying the row number.\n"
  putStrLn "Type 'exit' at any time to quit.\n"
  putStrLn "Two players or one? (1/2): "
  input <- getLine
  if input == "1" then
    gameLoop emptyBoard 'x' True
  else if input == "2" then
    gameLoop emptyBoard 'x' False
  else if input == "exit" then
    return ()
  else do
    putStrLn "Invalid input. Please input a '1' or '2'"
    main

type Board = [[Char]]
type Move = (Int, Int)
emptyBoard = ["   ", "   ", "   "]


restart :: IO()
restart = do
  putStrLn "Would you like to play again? (y/n)"
  playAgain <- getLine
  if playAgain == "y" then do
    putStrLn $ replicate 20 '\n'
    main
  else if playAgain == "n" then
    return ()
  else do
    putStrLn "Invalid input. Please enter 'y' or 'n'"
    restart

gameLoop :: Board -> Char -> Bool -> IO()
gameLoop board playerChar singlePlayer = do
  if singlePlayer && (playerChar == 'o') then do
    ms <- round `fmap` getPOSIXTime
    let cpuMove = getCPUMove board ms
    let newBoardTuple = doMove board cpuMove playerChar
    let newBoard = fst newBoardTuple
    if isWinner newBoard cpuMove then do
      putStrLn $ boardStr newBoard
      putStrLn "CPU wins!"
      restart
    else if catsGame newBoard then do
      putStrLn $ boardStr newBoard
      putStrLn "Tie game!"
      restart
    else
      gameLoop newBoard (nextChar playerChar) singlePlayer
  else do
    putStrLn $ "\n" ++ boardStr board ++ "\n"
    putStrLn $ "Player " ++ [playerChar] ++ ", please enter a move: (Example 'A0')"
    line <- getLine
    putStrLn $ replicate 20 '\n'
    if "exit" == line then
      return ()
    else do
      let move = parseMove line
      if snd move then do
        let newBoardTuple = doMove board (fst move) playerChar
        if snd newBoardTuple then do
          let newBoard = fst newBoardTuple
          if isWinner newBoard (fst move) then do
            putStrLn $ boardStr newBoard
            putStrLn $ "Player " ++ [playerChar] ++ " is the winner!"
            restart
          else if catsGame newBoard then do
            putStrLn $ boardStr newBoard
            putStrLn $ "Tie Game!"
            restart
          else
            gameLoop newBoard (nextChar playerChar) singlePlayer
        else do
          putStrLn "Out of bounds! / Player already there!"
          putStrLn "Please try again."
          gameLoop board playerChar singlePlayer
      else do
        putStrLn "Invalid move.\nPlease try again."
        gameLoop board playerChar singlePlayer


getCPUMove :: Board -> Int -> Move
getCPUMove board seed
  | snd $ doMove board (x,y) 'o'  = (x,y)
  | otherwise                     = getCPUMove board ((7*seed)+67)
  where
    size  = length board
    x     = seed `mod` size
    y     = (seed `div` 10) `mod` size

doMove :: Board -> Move -> Char -> (Board, Bool)
doMove b m player
    | x < 0 || y < 0 || x >= w || y >= h  = (b, False)
    | get2d x y b /= ' '                  = (b, False)
    | otherwise                           = (put2d x y player b, True)
  where
    x = fst m
    y = snd m
    w = length $ head b
    h = length b

parseMove :: String -> (Move, Bool)
parseMove str
    | length str /= 2                                 = badMove
    | (elem l ['A'..'Z'] || elem l ['a'..'z']) && elem n ['0'..'9']  = ( (charToInt l, ord n-48), True )
    | otherwise                                       = badMove
  where
    l = toUpper $ head str
    n = str !! 1
    badMove = ((0,0), False)
    charToInt c = ord (toUpper c) - 65

boardStr :: Board -> String
boardStr board =
  letterHeader ++ "\n\n" ++ intercalate rowSep (labelRowStr $ map rowStr board)
  where
    width         = length $ head board
    rowStr        = intercalate " | " . map (: [])
    labelRowStr s = [show n ++ "  " ++ x | n <- [0..length s-1], x <- [s!!n]]
    letterHeader  = "   " ++ intercalate "   " (strArr $ take width ['A'..])
    rowSep        = "\n   " ++ tail (init $ intercalate "+" $ replicate width "---") ++ "\n"

isWinner :: Board -> Move -> Bool
isWinner b m = vert || horiz || diagUpperLeft || diagUpperRight
  where
    dUL             = diagUL b
    dUR             = diagUR b
    vert            = allSame $ b !! snd m
    horiz           = allSame $ map (!! fst m) b
    diagUpperLeft   = not (all (== ' ') dUL) && allSame dUL
    diagUpperRight  = not (all (== ' ') dUR) && allSame dUR

catsGame :: Board -> Bool
catsGame = not . any (elem ' ')

put :: Int -> a -> [a] -> [a]
put pos newVal list = take pos list ++ newVal : drop (pos+1) list

put2d :: Int -> Int -> a -> [[a]] -> [[a]]
put2d x y newVal mat = put y (put x newVal (mat!!y)) mat

get2d :: Int -> Int -> [[a]]  -> a
get2d x y mat = (mat!!y)!!x

strArr :: String -> [String]
strArr = map (: [])

nextChar :: Char -> Char
nextChar current = if current == 'x' then 'o' else 'x'

allSame :: Eq a => [a] -> Bool
allSame (x:xs) = all (==x) xs

diagUR :: [[a]] -> [a]
diagUR xs = [(xs!!n)!!n | n <- [0..length xs -1]]

diagUL :: [[a]] -> [a]
diagUL xs = [(xs!!n)!!(len - n -1) | n <- [0..len-1]]
  where len = length xs
