
const express = require('express')
const app = express()
const MongoClient = require("mongodb").MongoClient;
const port = 3000

var d = null
var collection = null

// change with ur data
const mongoClient = new MongoClient("", { useNewUrlParser: true, useUnifiedTopology: true  });
mongoClient.connect(function(err, client){
 
  if(err){
      return console.log(err);
  }

  d = client.db("sea_battle");
  collection = d.collection("Games")
  // взаимодействие с базой данных
});


app.get("/", (request, response) => {
  //response.send('Hello from Express!')
  collection.find({}).toArray(function(err, person) {
          // console.log(JSON.stringify(person, null, 2));
          response.send(person)
      });
})

// Parse URL-encoded bodies (as sent by HTML forms)
app.use(express.urlencoded());

// Parse JSON bodies (as sent by API clients)
app.use(express.json());

// Access the parse results as request.body
app.post('/', function(request, response){
//  console.log(request.body);
  var query = { name: request.body.name };
  collection.deleteOne(query, function(err, obj) {
      if (err) throw err;
      console.log("1 document deleted");
    });
  collection.insertOne(request.body, function(err, res) {
      if (err) throw err;
      console.log("Document inserted");
      // close the connection to db when you are done with it
  });
});

app.post('/edit', function(request, response){
 // console.log(request.body)
  var myquery = { name: request.body.name };
  var newvalues = { $set: {gameType: request.body.gameType } };
  collection.updateOne(myquery, newvalues, function(err, res) {
  if (err) throw err;
  console.log("1 document updated");
});
});

app.post('/check', function(request, response) {
  // use `findOne` rather than `find`
  //console.log(request.body)
  collection.findOne({ 'name' : request.body.name ,
   'player2Ready': request.body.player2Ready}, function(err, user) {
     // hanlde err..
     if (user) {
         response.send("true")
       // user exists 
     } else {
         response.send("false")
       // user does not exist
     }
  })
})

app.post('/delete', function(request, response){
  // console.log(request.body);
   var query = { name: request.body.name };
   collection.deleteOne(query, function(err, obj) {
       if (err) throw err;
       console.log("1 document deleted");
     });
});

app.listen(port, (err) => {
  if (err) {
      return console.log('something bad happened', err)
  }
  console.log(`server is listening on ${port}`)
})