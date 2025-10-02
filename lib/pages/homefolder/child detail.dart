import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'child_detail_sections.dart';

class ChildDetailPage extends StatelessWidget {
  final Map<String, dynamic> childData;
  final String childName;

  const ChildDetailPage({super.key, required this.childData, required this.childName});

  @override
  Widget build(BuildContext context) {
    final childInfo = childData['data']['childInfo'] as Map<String, dynamic>;
    final parentInfo = childData['data']['parentGuardianInfo'] as Map<String, dynamic>;
    final vaccinationDetails = childData['data']['vaccinationDetails'] as Map<String, dynamic>;
    final address = childInfo['address'] as Map<String, dynamic>;
    final imageUrl = childInfo['imageUrl'] as String?;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade50, Colors.teal.shade100],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: const Color(0xFF26A69A), // Teal shade for AppBar
              elevation: 4,
              pinned: true,
              expandedHeight: 220.0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Hero(
                  tag: 'childName-${childData.hashCode}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      childName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF26A69A).withOpacity(0.9),
                            const Color(0xFF4DB6AC).withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 16,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: imageUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: 96,
                                  height: 96,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.teal,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      childName.isNotEmpty ? childName[0].toUpperCase() : 'C',
                                      style: GoogleFonts.poppins(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  childName.isNotEmpty ? childName[0].toUpperCase() : 'C',
                                  style: GoogleFonts.poppins(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child Information Section
                _buildSectionCard(
                  title: 'Child Information',
                  child: buildChildInfoSection(childInfo),
                ),
                const SizedBox(height: 16),
                // Address Section
                _buildSectionCard(
                  title: 'Address',
                  child: buildAddressSection(address),
                ),
                const SizedBox(height: 16),
                // Parent/Guardian Information Section
                _buildSectionCard(
                  title: 'Parent/Guardian Information',
                  child: buildParentInfoSection(parentInfo),
                ),
                const SizedBox(height: 16),
                // Vaccination Details Section
                _buildSectionCard(
                  title: 'Vaccination Details',
                  child: buildVaccinationDetailsSection(vaccinationDetails),
                ),
                const SizedBox(height: 16),
                // Member Information Section
                _buildSectionCard(
                  title: 'Member Information',
                  child: buildMemberInfoSection(childData),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}