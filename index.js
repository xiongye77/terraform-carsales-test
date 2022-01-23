exports.handler = async function (event, context) {
    return {
        "isBase64Encoded": false,
        "statusCode": 200,
        "statusDescription": "200 OK",
         "headers": {
         "Content-Type": "text/html"
         },
        "body": "<h1>Hello from Lambda!</h1>"
    } 
}
