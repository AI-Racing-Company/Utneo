<?php



$arr = ["In this tutorial we’ll show you how to play our game UtNeO.<br /><br />

First, let’s start with your hand cards.<br />
Your hand cards are the heart of the game but you want to get rid of them to win the game.", "With your handcards and these operations above them you need to do MATH.<br />

In the middle of the screen you see which number you need to get with your hand cards and operations.", "But for example: you try 4x4 you see that you can’t get a number between zero and nine.", "But for example: you try 4x4 you see that you can’t get a number between zero and nine.<br />

In this case it’s the last digit of the number we care about.", "That means if you try 4+5 and in the middle is the number 9 you will get rid of two cards.<br />

After you have played your cards or the timer runs out it’s the other players turn.", "Down here is the clear button. With this button you undo the cards and operation you clicked.", "The button next to the clear button is the push button.<br />
With this push button you play your selected cards.<br /><br />

If you cannot play two card you can also play a single card with the same number or draw a card.<br /><br />

If you cannot play a card and run out of time you have to draw two cards.", "If you want to draw a card click this card here."];

$val = 1;


if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  // Something posted

  if (isset($_POST['prev'])) {
    $val = $_POST['prev'];
    if($val < 0){
      $val = 7;
    }
  } else if (isset($_POST['nex'])) {
    $val = $_POST['nex'];
    if($val > 7){
      $val = 0;
    }
  }
  if($val < 0){
    $val = 7;
  }
  if($val > 7){
    $val = 0;
  }
}

echo '<!DOCTYPE html>
<html lang="eb" dir="ltr">
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="sty.css">
    <title>Utneo</title>
  </head>
  <body>

    <table class="tab">
      <tr>
        <th>
          <img alt="null" src="Tutorial_pic0'.$val.'.jpeg" class="tutimg"/>
        </th>
        <th>
          '.$arr[$val].'
        </th>
      </tr>
      <tr>
        <form action="" method="post">
          <th>
            <input type="submit" name="prev" value="'.(($val - 1)%8).'">
          </th>
          <th>
            <input type="submit" name="nex" value="'.(($val + 1)%8).'">
          </th>
        </form>
      </tr>
    </table>
  </body>
</html>
';



 ?>
