port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (field, string, int , list)
import Json.Decode.Pipeline exposing (required)


-- MAIN
main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- PORTS
port sendMsg : String -> Cmd msg

-- inbound port
port receivedMsg : (String -> msg) -> Sub msg



-- MODEL
type alias Flags = {
  userID: String
  }

type alias Page = {
  comments: List Comment
  , totalPages: Int
  }

type alias Comment = 
  {
   id : Int
   , name: String
   , year: Int
   , color: String
  }


type Status
  = Failure
  | Loading
  | Success


type alias Model =
    { status : Status
    , page: Page
    , currentPage: Int
    , userID : String
    , messages : List String
    }

initialPage = Page [] 0

initialState : Flags -> Model
initialState flags = 
  Model Loading initialPage 1 flags.userID []

init : Flags -> (Model, Cmd Msg)
init flags =
  (initialState flags, getData 1)


-- UPDATE
type Msg
  = GotData (Result Http.Error Page)
  | PrevPage 
  | NextPage
  | SendData
  | GotMessage String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PrevPage  ->
      let
          newModel = { model | currentPage = model.currentPage - 1}
      in
         (newModel, getData newModel.currentPage)
    NextPage  ->
      let
          newModel = { model | currentPage = model.currentPage + 1}
      in
         (newModel, getData newModel.currentPage)
    GotData result ->
      case result of
        Ok page ->
          ({model | status = Success, page = page}, Cmd.none)
        Err _ ->
          ({model | status = Failure}, Cmd.none)
    GotMessage inboundMsg ->
      let
          newMessages = model.messages ++ [inboundMsg]
      in
        ({model | messages = newMessages}, Cmd.none)
    SendData ->
      (model, sendMsg "hello")


-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.batch 
    [ receivedMsg GotMessage
    ]

-- VIEW
view : Model -> Html Msg
view model =
  div []
    [ h1 [] [ text ("Welcome " ++ model.userID) ]
    , h2 [] [ text "Comments" ]
    , h4 [] [ text ("Page No: " ++ String.fromInt(model.currentPage)) ]
    , h4 [] [ text ("Total Pages: " ++ String.fromInt(model.page.totalPages)) ]
    , prevButton model 
    , postList model
    , nextButton model 
    , displayMessages model 
    , sendMessage model
    ]

sendMessage : Model -> Html Msg
sendMessage model =
  div []
  [ button [ onClick SendData] [ text "Send Message" ]
  ]

displayMessages : Model -> Html Msg
displayMessages model =
  div [] 
    [ h2 [] [ text "Messages"]
    , model.messages |> List.map (\m -> li [] [text m]) |> ul []
    ]

prevButton : Model -> Html Msg
prevButton model =
  if model.currentPage > 1 then
    button [onClick prevPage] [ text "Prev" ]
  else 
    text ""

nextButton : Model -> Html Msg
nextButton model =
  if model.currentPage < model.page.totalPages then
    button [onClick nextPage] [ text "Next" ]
  else 
    text ""

postList : Model -> Html Msg
postList model =
  case model.status of
    Failure ->
      div []
        [ text "I could not load posts for some reason. " ]

    Loading ->
      text "Loading..."

    Success ->
      model.page.comments
      |> List.map postItem
      |> div []

postItem : Comment -> Html Msg
postItem c = 
  div [] [
    h2 [style "color" c.color ] [ text ("ID: " ++ String.fromInt c.id) ]
    ,ul [] [ 
      li [] [ text ("Name: " ++ c.name) ] 
      ,li [] [ text ("Year: " ++ String.fromInt c.year) ] 
    ] 
  ]
    


-- HTTP
prevPage : Msg
prevPage =  
  PrevPage

nextPage : Msg
nextPage =  
  NextPage

getData : Int -> (Cmd Msg)
getData page =  
  Http.get
    { url = "https://reqres.in/api/comments?page=" ++ String.fromInt(page)
    , expect = Http.expectJson GotData dataDecoder
    }

commentDecoder =
  Decode.succeed Comment
    |> required "id" int
    |> required "name" string 
    |> required "year" int 
    |> required "color" string 

dataDecoder =
  Decode.succeed Page
    |> required "data" (list commentDecoder)
    |> required "total_pages" int
