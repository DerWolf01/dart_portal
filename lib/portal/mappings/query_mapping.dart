/// A metadata annotation to map all query parameter to an endpoint parameter.
/// A query parameter is a key-value pair in the URL of a request.
/// No name can be specified in the annotation as al query parameters will get mapped to the anotated method parameter.
/// The method parameter must be a Model or an Map<String, String> to hold all query parameters .
class QueriesMapping {
  const QueriesMapping();
}

class QueryMapping {
  /// The name of the query parameter.
  /// If not specified, the name of the parameter it was anotated on will be used.
  final String? name;

  /// A metadata annotation to map a query parameter to an endpoint parameter.
  /// A query parameter is a key-value pair in the URL of a request.
  /// The name of the query parameter can be specified in the annotation.
  /// If not specified, the name of the parameter it was anotated on will be used.
  const QueryMapping({this.name});
}
