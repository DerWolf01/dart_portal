# Portal

Portal is a Dart-based open source server-client communication framework that leverages portals and the reflectable package to dynamically handle requests and responses. It provides a structured way to manage socket communication, making it easier to develop scalable and maintainable real-time applications.

## Features

- **Portal-Based Architecture**: Organize your code into portals for both server & client to handle specific paths and actions, improving modularity and readability.
- **Interceptor Support**: Easily add middleware for request preprocessing and postprocessing.
- **Serializable Models**: Define models that can be automatically serialized and deserialized from JSON, streamlining client-server data exchange.
- **Reflectable**: Utilizes Dart's reflectable package for runtime reflection, enabling dynamic invocation of methods based on request paths.

## Getting Started

To get started with Portal, follow these steps:

1. **Add Dependencies**: Ensure you have `portal`, `reflectable` and `build_runner` added to your `pubspec.yaml` file. 
   1. Make sure to define 'analyzer: ^6.4.0' ( bigger version have conflcits with reflectable & build_runner ) 

          ```yaml
          dependencies:
            portal: ^latest_version
            reflectable: ^latest_version
            analyzer: ^6.4.0
          dev_dependencies:
            build_runner: ^latest_version
          ```
   2. **Define Portals**: Create portals annotated with `@Portal` to handle specific paths and actions. Use `@Get` and `@ResponseHandler` to define methods for handling requests and responses. 
      

```dart 
//server side code   
@Portal('/example')

class ExamplePortalServer {

  // This method will now act as an handler for the path /example/sayHello
  // It has to return SocketMessage as value & has to match the same argument type of the handler in the client side!
  // If it doesn't either on the client- or server side an exception will be thrown because of incompatible types

  @Get('/sayHello')
  SocketMessage sayHello(SocketMessage request) {
    // this will be the response to the client
    print("client says: ${request.text}");
    return SocketMessage('Hello Client!');
  }
}
//... 
   ```
```dart
import 'package:portal/portal.dart';

// This class will be available on both client and server side

class SocketMessage extends SerializableModel {
  String text;

  SocketMessage(this.text);

//...member methods: toJson, toMap...
}
 

//...client side code 

@Portal('/example')
class ExamplePortalClient {

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
  PortalClient client = await PortalClient.connect("localhost", 3000);
  // this will send the message to the server
  // the above defined portal will handle everything else
  await ClientMessageService().send(SocketMessage("Hello Server!"));
}
```

3. **Register Portals**: Before running your application, register your portals with the framework.

    ```dart
    void main() {
      PortalService().registerPortal(ExamplePortal());
      // Start your server or client
    }
    ```


4. **Define Middlewares**: Create middlewares to preprocess and postprocess requests and responses. Use the `InterceptorService` to register your middleware.

    ```dart
    import 'package:portal/portal.dart';

    var exampleMiddleware = Interceptor<SocketMessage>("/example", preHandle: (accepts) async => true, postHandle: (portalReceived, {portalGaveBack}) async => print(portalReceived));
    
   ```

5. **Register Interceptor**: Before running your application, register your middleware with the framework.

    ```dart
    void main() {
      //...
      InterceptorService().registerMiddleware(exampleMiddleware);
      //or use the member method
      exampleMiddleware.register();
      //or use the anonymousMiddleware function if you do not wanna define a class
      anonymousMiddleware("/example", preHandle: (UInt8List request) {
        print("Interceptor for /example");
        return true;
      }, postHandle: (SerializableModel portalReceived, {SerializableModel? portalGaveBack}) {
        print("Interceptor for /example");
      });
      // Start your server or client
    }
    ```

5. **Use Build Runner**: Portal uses the reflectable package, which requires generating code. Run the build runner to generate the necessary files.

    ```shell
    dart run build_runner build
    ```

6. **Run Your Application**: With all portals registered and necessary files generated, your application is ready to run.

## Important Notes

- **Portal Registration**: Ensure all portals are registered before starting your server or client to avoid runtime errors.
- **Build Runner**: Always run the build runner after making changes to portals or models to regenerate the necessary reflective files.
- **Import generated file**: Import the generated file `portal.reflectable.dart` in your main file and call "initializeReflectable()" to enable reflection.

    ```dart
    import 'portal.reflectable.dart';
  
    void main() {
      PortalService().registerPortal(ExamplePortal());
      initializeReflectable();
      // Register portals and start your server or client
    }
    ```
## Example

Here's a simple example of a Portal server and client setup:

- **Server**: Listens for connections and handles requests using registered portals.
- **Client**: Connects to the server and sends requests based on user actions or application logic.

For detailed examples and advanced usage, refer to the `examples` directory in the Portal repository.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve Portal.

## License

Portal is released under the MIT License. See the LICENSE file for more details.
