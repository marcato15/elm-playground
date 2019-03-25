import {Socket} from "phoenix"; 

const token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJwcm9kaWN0aW9ucyIsImV4cCI6MTU1NTg5MTUxMSwiaWF0IjoxNTUzNDcyMzExLCJpc3MiOiJwcm9kaWN0aW9ucyIsImp0aSI6IjhkZjFmMmU2LWJmZTctNDIxNC1iNDg1LTNiYTA0NDczYzQxNiIsIm5iZiI6MTU1MzQ3MjMxMCwic3ViIjoiMTIzIiwidHlwIjoiYWNjZXNzIn0.ZeQ9Rn5BZ7_cUl_CrihqUMkQSxHUES1Qx-aPCgqG0TQsUrN_xQ1EL0lqRHtwgKaifs4CCptpdnkMgHcI4GOL3w";

// Initiate Web Socket
const socket = new Socket("ws://localhost:4000/socket", {params: {token}});
socket.connect();
const channel = socket.channel("room:1234", {});
channel.join();

const userID = '123456';
const app = Elm.Main.init({
  node: document.getElementById('elm'),
  flags: { userID },
});

channel.on("new_response", ({ body }) => {
  app.ports.receivedMsg.send(body);
});

app.ports.sendMsg.subscribe( body => {
  channel.push("new_msg", {body}, 1000)
    .receive("ok", (msg) => console.log("created message", msg) )
    .receive("error", (reasons) => console.log("create failed", reasons) )
});


