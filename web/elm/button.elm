module Main exposing (..)
-- module main

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

-- minimal import for rekursion

-- MAIN


main =
  Browser.sandbox { init = init, update = update, view = view }

-- main = Browser.sandbox {
--  init,
--  update,
--  view,
--}

-- MODEL


type alias Model = Int
-- type Model = distinct Int

init : Model
init = 0

-- UPDATE

type Msg = Increment | Decrement


update : Msg -> Model -> Model
update msg model =
  case msg of
    Increment ->
      model + 1

    Decrement ->
      model - 1

--update msg model = match msg {
--Increment -> model + 1
--Decrement -> model - 1
--}
-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (String.fromInt model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]

--view model =
--div []
--  [ button [ onClick Decrement ] [ text "-" ]
--  , div [] [ text (String.fromInt model) ]
--  , button [ onClick Increment ] [ text "+" ]
--  ]