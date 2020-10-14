
class ListCursor {

  final String previous;
  final String next;

  ListCursor(this.previous, this.next);
}

class ListResponse<Item> {

  final List<Item> items;
  final ListCursor cursor; 

  ListResponse(this.items, this.cursor);
}