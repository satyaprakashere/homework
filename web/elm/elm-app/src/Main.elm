module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)

-- MAIN
main =
  Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type Page = Home | Editor | Blog

type alias Post =
    { title : String
    , date : String
    , content : String
    }

type alias Model =
    { page : Page
    , count : Int
    , editorContent : String
    , posts : List Post
    }

init : Model
init =
    { page = Home
    , count = 0
    , editorContent = ""
    , posts = 
        [ { title = "The Beauty of Elm", date = "April 20, 2026", content = "Elm brings delight to web development with its strong type system and friendly error messages." }
        , { title = "Functional Thinking", date = "April 15, 2026", content = "Moving from imperative to functional code requires a shift in perspective, but the rewards in reliability are immense." }
        , { title = "Pure Aesthetics", date = "April 10, 2026", content = "A great application isn't just about code; it's about how it feels to the user. Design matters." }
        ]
    }

-- UPDATE
type Msg
    = ChangePage Page
    | Increment
    | Decrement
    | UpdateEditor String
    | ClearEditor

update : Msg -> Model -> Model
update msg model =
  case msg of
    ChangePage newPage ->
        { model | page = newPage }
    Increment ->
        { model | count = model.count + 1 }
    Decrement ->
        { model | count = model.count - 1 }
    UpdateEditor content ->
        { model | editorContent = content }
    ClearEditor ->
        { model | editorContent = "" }

-- VIEW
view : Model -> Html Msg
view model =
    div [ class "app-container" ]
        [ viewHeader model.page
        , main_ [ class "content" ]
            [ case model.page of
                Home -> viewHome model
                Editor -> viewEditor model
                Blog -> viewBlog model
            ]
        , viewFooter
        ]

viewHeader : Page -> Html Msg
viewHeader currentPage =
    header [ class "header" ]
        [ div [ class "logo" ] [ text "ElmApp" ]
        , nav [ class "nav" ]
            [ navLink Home "Home" currentPage
            , navLink Editor "Editor" currentPage
            , navLink Blog "Blog" currentPage
            ]
        ]

navLink : Page -> String -> Page -> Html Msg
navLink page label currentPage =
    a 
        [ classList [ ("nav-item", True), ("active", page == currentPage) ]
        , onClick (ChangePage page)
        ] 
        [ text label ]

viewHome : Model -> Html Msg
viewHome model =
    div [ class "page home-page" ]
        [ h1 [] [ text "Welcome Home" ]
        , p [] [ text "This is a simple Elm application showcasing different features." ]
        , div [ class "counter-box" ]
            [ button [ class "btn btn-round", onClick Decrement ] [ text "−" ]
            , span [ class "count-display" ] [ text (String.fromInt model.count) ]
            , button [ class "btn btn-round", onClick Increment ] [ text "+" ]
            ]
        ]

viewEditor : Model -> Html Msg
viewEditor model =
    div [ class "page editor-page" ]
        [ h1 [] [ text "Text Editor" ]
        , p [] [ text "Draft your thoughts here. The state is preserved as you navigate." ]
        , div [ class "editor-container" ]
            [ textarea 
                [ class "text-editor"
                , placeholder "Start typing..."
                , value model.editorContent
                , onInput UpdateEditor
                ] []
            , div [ class "editor-actions" ]
                [ button [ class "btn btn-danger", onClick ClearEditor ] [ text "Clear" ]
                , div [ class "char-count" ] [ text (String.fromInt (String.length model.editorContent) ++ " characters") ]
                ]
            ]
        ]

viewBlog : Model -> Html Msg
viewBlog model =
    div [ class "page blog-page" ]
        [ h1 [] [ text "Our Blog" ]
        , div [ class "post-list" ]
            (List.map viewPost model.posts)
        ]

viewPost : Post -> Html Msg
viewPost post =
    article [ class "blog-post" ]
        [ h2 [] [ text post.title ]
        , div [ class "post-meta" ] [ text post.date ]
        , p [ class "post-content" ] [ text post.content ]
        ]

viewFooter : Html Msg
viewFooter =
    footer [ class "footer" ]
        [ text "© 2026 ElmApp Homework Project" ]