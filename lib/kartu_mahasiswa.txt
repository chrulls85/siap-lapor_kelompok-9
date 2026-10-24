import 'package:flutter/material.dart';

class KartuMahasiswa extends StatelessWidget {
  final String nama;
  final String nim;
  final String programStudi;

  const KartuMahasiswa({
    super.key,
    required this.nama,
    required this.nim,
    required this.programStudi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.0,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            spreadRadius: 2.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle,
            size: 60,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Diubah dari black80 ke black87
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 24, thickness: 1.2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NIM:", style: TextStyle(fontWeight: FontWeight.w600)),
              Text(nim),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Prodi:", style: TextStyle(fontWeight: FontWeight.w600)),
              Text(programStudi),
            ],
          ),
        ],
      ),
    );
  }
}