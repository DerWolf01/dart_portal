# Wormhole

Wormhole is a Dart-based open source server-client communication framework that leverages controllers and the reflectable package to dynamically handle requests and responses. It provides a structured way to manage socket communication, making it easier to develop scalable and maintainable real-time applications.

## Features

- **Controller-Based Architecture**: Organize your code into controllers for both server & client to handle specific paths and actions, improving modularity and readability.
- **Middleware Support**: Easily add middleware for request preprocessing and postprocessing.
- **Serializable Models**: Define models that can be automatically serialized and deserialized from JSON, streamlining client-server data exchange.
- **Reflectable**: Utilizes Dart's reflectable package for runtime reflection, enabling dynamic invocation of methods based on request paths.

## Getting Started

To get started with Wormhole, follow these steps:

1. **Add Dependencies**: Ensure you have `wormhole`, `reflectable` and `build_runner` added to your `pubspec.yaml` file. 
   1. Make sure to define 'analyzer: ^6.4.0' ( bigger version have conflcits with reflectable & build_runner ) 

          ```yaml
          dependencies:
            wormhole: ^latest_version
            reflectable: ^latest_version
            analyzer: ^6.4.0
          dev_dependencies:
            build_runner: ^latest_version
          ```
   2. **Define Controllers**: Create controllers annotated with `@Controller` to handle specific paths and actions. Use `@RequestHandler` and `@ResponseHandler` to define methods for handling requests and responses. 
      

```dart 
//server side code   
@Controller('/example')
@component
class ExampleControllerServer {

  // This method will now act as an handler for the path /example/sayHello
  // It has to return SocketMessage as value & has to match the same argument type of the handler in the client side!
  // If it doesn't either on the client- or server side an exception will be thrown because of incompatible types

  @RequestHandler('/sayHello')
  SocketMessage sayHello(SocketMessage request) {
    // this will be the response to the client
    print("client says: ${request.text}");
    return SocketMessage('Hello Client!');
  }
}
//... 
   ```
```dart
import 'package:wormhole/wormhole.dart';

// This class will be available on both client and server side
@component
class SocketMessage extends SerializableModel {
  String text;

  SocketMessage(this.text);

//...member methods: toJson, toMap...
}
 

//...client side code 
@component
@Controller('/example')
class ExampleControllerClient {

  // This method will now act as an response handler for the path /example/sayHello
  // It will not be used to responed the server as it is an response handler only!
  // If it doesn't either on the client- or server side an exception will be thrown because of incompatible types
  // The Response and Request handler with the sane paths have to match the same types when it comes to the handler argument  
  @ResponseHandler('/sayHello')
  void sayHello(SocketMessage response) {
    print("server says: ${response.text}");
    //... 
  }
}
//...
void main() async {
  WormholeClient client = await WormholeClient.connect("localhost", 3000);
  // this will send the message to the server
  // the above defined controller will handle everything else
  await ClientMessageService().send(SocketMessage("Hello Server!"));
}
```

3. **Register Controllers**: Before running your application, register your controllers with the framework.

    ```dart
    void main() {
      ControllerService().registerController(ExampleController());
      // Start your server or client
    }
    ```


4. **Define Middlewares**: Create middlewares to preprocess and postprocess requests and responses. Use the `MiddlewareService` to register your middleware.

    ```dart
    import 'package:wormhole/wormhole.dart';

    var exampleMiddleware = Middleware<SocketMessage>("/example", preHandle: (accepts) async => true, postHandle: (controllerAccepted, {controllerReturned}) async => print(controllerAccepted));
    
   ```

5. **Register Middleware**: Before running your application, register your middleware with the framework.

    ```dart
    void main() {
      //...
      MiddlewareService().registerMiddleware(exampleMiddleware);
      //or use the member method
      exampleMiddleware.register();
      //or use the anonymousMiddleware function if you do not wanna define a class
      anonymousMiddleware("/example", preHandle: (UInt8List request) {
        print("Middleware for /example");
        return true;
      }, postHandle: (SerializableModel controllerAccepted, {SerializableModel? controllerReturned}) {
        print("Middleware for /example");
      });
      // Start your server or client
    }
    ```

5. **Use Build Runner**: Wormhole uses the reflectable package, which requires generating code. Run the build runner to generate the necessary files.

    ```shell
    dart run build_runner build
    ```

6. **Run Your Application**: With all controllers registered and necessary files generated, your application is ready to run.

## Important Notes

- **Controller Registration**: Ensure all controllers are registered before starting your server or client to avoid runtime errors.
- **Build Runner**: Always run the build runner after making changes to controllers or models to regenerate the necessary reflective files.
- **Import generated file**: Import the generated file `wormhole.reflectable.dart` in your main file and call "initializeReflectable()" to enable reflection.

    ```dart
    import 'wormhole.reflectable.dart';
  
    void main() {
      ControllerService().registerController(ExampleController());
      initializeReflectable();
      // Register controllers and start your server or client
    }
    ```
## Example

Here's a simple example of a Wormhole server and client setup:

- **Server**: Listens for connections and handles requests using registered controllers.
- **Client**: Connects to the server and sends requests based on user actions or application logic.

For detailed examples and advanced usage, refer to the `examples` directory in the Wormhole repository.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve Wormhole.

## License

Wormhole is released under the MIT License. See the LICENSE file for more details.
