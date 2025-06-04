import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MultiSelectDropdownButtonFormField extends FormField<List<String?>> {
  final List<String> items;
  final String title;
  final List<String?> selectedItems;
  final void Function(List<String?>) onConfirm;
  static const IconData close = IconData(0xe16a, fontFamily: 'MaterialIcons');

  MultiSelectDropdownButtonFormField({
    required this.items,
    required this.title,
    required this.selectedItems,
    required this.onConfirm,
    FormFieldSetter<List<String?>>? onSaved,
    FormFieldValidator<List<String?>>? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    Key? key,
    required Color chipBackGroundColor,
  }) : super(
    onSaved: onSaved,
    validator: validator,
    initialValue: selectedItems,
    autovalidateMode: autovalidateMode,
    builder: (FormFieldState<List<String?>> state) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final results = await showModalBottomSheet<List<String?>>(
                  context: state.context,
                  isScrollControlled:
                  true, // For fullscreen or larger view
                  builder: (BuildContext context) {
                    return MultiSelectBottomSheet(
                      items: items,
                      title: title,
                      selectedItems: state.value!,
                    );
                  },
                );
                if (results != null) {
                  state.didChange(results);
                  onConfirm(results);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  border: InputBorder.none,
                  // OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(4),
                  // ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Symbols.keyboard_arrow_down),
                      ],
                    ),
                    // Wrap(
                    //   spacing: 6,
                    //   children: state.value!.map((item) {
                    //
                    //     return Chip(
                    //       label: Text(item!,
                    //         style: TextStyle(fontSize: 11),
                    //       ),
                    //       onDeleted: () {
                    //         state.didChange(state.value!..remove(item));
                    //       },
                    //       deleteIcon: Icon(
                    //         close, // Custom icon for unselect
                    //         color: Colors.grey, // Change the color
                    //         size: 14, // Adjust size
                    //       ),
                    //
                    //       backgroundColor: chipBackGroundColor,
                    //       labelStyle: TextStyle(color: Colors.blue ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(100), // Set your desired radius
                    //         side: BorderSide(color: Colors.grey, width: 0.5),
                    //       ),
                    //       padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    //       labelPadding: EdgeInsets.only(left: 4 , right: 0),
                    //     );
                    //   }).toList(),
                    // ),
                    // if (state.value!.length > 2)
                    //   Chip(
                    //     label: Text(
                    //       '+${state.value!.length - 2}',
                    //       style: TextStyle(fontSize: 11, color: Colors.black),
                    //     ),
                    //     backgroundColor: Colors.grey.shade300,
                    //   ),
                    Wrap(
                      spacing: 6,
                      children: [
                        // Show the first two selected items as chips
                        ...state.value!.take(2).map((item) {
                          return Chip(
                            label: Text(
                              item!,
                              style: TextStyle(fontSize: 11),
                            ),
                            onDeleted: () {
                              state.didChange(state.value!..remove(item));
                            },
                            deleteIcon: Icon(
                              close,
                              color: Colors.grey,
                              size: 14,
                            ),
                            backgroundColor: chipBackGroundColor,
                            labelStyle: TextStyle(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(color: Colors.grey, width: 0.5),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            labelPadding: EdgeInsets.only(left: 4, right: 0),
                          );
                        }).toList(),
                        // Show "+n" if more than 2 items are selected
                        if (state.value!.length > 2)
                          Chip(
                            label: Text(
                              '+${state.value!.length - 2}',
                              style: TextStyle(fontSize: 11, color: Colors.blue),
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(color: Colors.grey, width: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class MultiSelectBottomSheet extends StatefulWidget {
  final List<String> items;
  final String title;
  final List<String?> selectedItems;

  MultiSelectBottomSheet({
    required this.items,
    required this.title,
    required this.selectedItems,
  });

  @override
  _MultiSelectBottomSheetState createState() => _MultiSelectBottomSheetState();
}

class _MultiSelectBottomSheetState extends State<MultiSelectBottomSheet> {
  late List<String?> _tempSelectedItems;
  List<String> _filteredItems = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List<String?>.from(widget.selectedItems);
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height *
          0.6, // Set height to 80% of screen
      child: Column(
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       widget.title,
          //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          //     ),
          //     IconButton(
          //       icon: Icon(Icons.close),
          //       onPressed: () => Navigator.pop(context),
          //     ),
          //   ],
          // ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(
                  fontSize: 14.0
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors
                        .blue), // Active color for the bottom border
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors
                        .grey.shade300), // Inactive color for the bottom border
              ),
              prefixIcon: Icon(Icons.search , size: 18.0,),
            ),
            onChanged: _filterItems,
          ),
          Expanded(
            child: ListView(
              children: _filteredItems.map((item) {
                return ListTile(
                  minLeadingWidth: 0,
                  horizontalTitleGap: 0,
                  minVerticalPadding: 0,
                  dense: true,
                  leading: Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: _tempSelectedItems.contains(item),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _tempSelectedItems.add(item);
                          } else {
                            _tempSelectedItems.remove(item);
                          }
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      checkColor: Colors.white,
                      activeColor: Colors.blue,
                      visualDensity: VisualDensity(vertical:-4, horizontal: -4 ),
                    ),
                  ),
                  title: Text(item , style: TextStyle(color: Colors.grey),),
                  contentPadding: EdgeInsets.zero, // No padding around the tile
                  onTap: () {
                    setState(() {
                      if (_tempSelectedItems.contains(item)) {
                        _tempSelectedItems
                            .remove(item); // Uncheck if already checked
                      } else {
                        _tempSelectedItems.add(item); // Check if unchecked
                      }
                    });
                  },
                );

                //   CheckboxListTile(
                //   title: Text(item),
                //   controlAffinity: ListTileControlAffinity.leading,
                //   value: _tempSelectedItems.contains(item),
                //   contentPadding: EdgeInsets.zero,
                //   onChanged: (bool? checked) {
                //     setState(() {
                //       if (checked == true) {
                //         _tempSelectedItems.add(item);
                //       } else {
                //         _tempSelectedItems.remove(item);
                //       }
                //     });
                //   },
                // );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TextButton(
              //   child: Text('CANCEL'),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              // ),
              // TextButton(
              //   child: Text(
              //     'Cancel',
              //     style: TextStyle(
              //         color: Colors.blue.shade800), // Set text color to grey
              //   ),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              //   style: TextButton.styleFrom(
              //     side: BorderSide(
              //         color: Colors.grey), // Set border color to grey
              //     shape: RoundedRectangleBorder(
              //       // Set the shape to rectangular
              //       borderRadius: BorderRadius.circular(2), // No rounding
              //     ),
              //   ),
              // ),
              // ElevatedButton(
              //   child: Text(
              //     'OK',
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   onPressed: () {
              //     Navigator.pop(context, _tempSelectedItems);
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor:
              //         Colors.blue.shade800, // Set the background color to blue
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(
              //           2), // Set the border radius to zero for rectangular shape
              //     ),
              //   ),
              // )
              // OutlinedButton(
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              //   style: OutlinedButton.styleFrom(
              //       side: BorderSide(color: Colors.grey), // Set border color to grey
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8), // No rounding
              //       ),
              //       minimumSize: Size(0.0, 30.0)
              //   ),
              //   child: Text(
              //     'Cancel',
              //     style: TextStyle(
              //       color: Colors.blue, // Set text color to blue
              //     ),
              //   ),
              // ),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade200, // No background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),

                  ),
                  minimumSize: Size(0.0, 20.0), // Button size
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.blue, // Set text color to blue
                  ),
                ),
              ),

              // OutlinedButton(
              //   child: Text(
              //     'OK',
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   onPressed: () {
              //     Navigator.pop(context, _tempSelectedItems);
              //   },
              //   style: OutlinedButton.styleFrom(
              //       backgroundColor: Colors.blue,
              //
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8), // Set the border radius
              //       ),
              //       minimumSize: Size(0.0, 30.0)
              //   ),
              //
              // )

              ElevatedButton(
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(context, _tempSelectedItems);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  minimumSize: Size(0.0, 30.0), // Button size
                ),
              )

            ],
          ),
        ],
      ),
    );
  }
}


