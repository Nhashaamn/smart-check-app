import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_check/teamController.dart';

class BarWidget extends StatelessWidget {
  final bool isDropdownVisible;
  final VoidCallback toggleDropdown;

  const BarWidget({
    super.key,
    required this.isDropdownVisible,
    required this.toggleDropdown,
  });

  @override
  Widget build(BuildContext context) {
    final TeamController teamController = Get.find();

    return GestureDetector(
      onTap: toggleDropdown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 200,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Flexible(
                    child: Text(
                      teamController.selectedTeamName.value.isEmpty
                          ? "Select Team"
                          : teamController.selectedTeamName.value,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
              Icon(
                isDropdownVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}