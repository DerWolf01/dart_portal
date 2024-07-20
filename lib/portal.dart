library portal;

export 'package:portal/portal/portal_service.dart';
export 'package:portal/interceptor/intercept.dart';
export 'package:portal/interceptor/interceptor_service.dart';

import 'package:portal/reflection.dart';

/// An abstract class representing a type of request that can be handled by the application.
///
/// This class serves as a base for more specific request handler annotations, such as
/// [RequestHandler] and [Post]. It includes a `path` property that is used
/// for routing requests to the appropriate handler based on the URL path.
