import 'package:flutter/material.dart';

class ProvincePicker extends StatefulWidget {
  final List<String> provinces;
  final Function(String) onProvinceSelected;

  const ProvincePicker({
    super.key,
    required this.provinces,
    required this.onProvinceSelected,
  });

  @override
  _ProvincePickerState createState() => _ProvincePickerState();
}

class _ProvincePickerState extends State<ProvincePicker> {
  String searchQuery = '';
  late List<String> filteredProvinces;

  @override
  void initState() {
    super.initState();
    filteredProvinces = widget.provinces;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เลือกจังหวัด'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'ค้นหาจังหวัด',
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    filteredProvinces = widget.provinces
                        .where((province) => province.contains(searchQuery))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200, // จำกัดความสูงของ ListView
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredProvinces.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredProvinces[index]),
                      onTap: () {
                        widget.onProvinceSelected(filteredProvinces[index]);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
