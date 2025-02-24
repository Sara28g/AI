import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'dart:math' as math;

enum ServiceCategory {
  jobs,
  shelter,
  crisis,
  legal,
  counseling,
  community,
  medical,
}

class Organization {
  final String name;
  final String contact;
  final String hours;
  final String address;
  final String description;
  final ServiceCategory category;
  final vmath.Vector2 position;
  final Color color;
  final String homeLabel;

  Organization({
    required this.name,
    required this.contact,
    required this.hours,
    required this.address,
    required this.description,
    required this.category,
    required this.position,
    required this.color,
    required this.homeLabel,
  });
}

class HelpMapScreen extends StatefulWidget {
  const HelpMapScreen({Key? key}) : super(key: key);

  @override
  State<HelpMapScreen> createState() => _HelpMapScreenState();
}

class _HelpMapScreenState extends State<HelpMapScreen> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  final double mapWidth = 1000.0;
  final double mapHeight = 1500.0;

  Organization? _selectedOrg;
  late final Map<ServiceCategory, List<Organization>> _organizationsByCategory;

  final Map<ServiceCategory, bool> _categoryVisibility = {
    ServiceCategory.jobs: true,
    ServiceCategory.shelter: true,
    ServiceCategory.crisis: true,
    ServiceCategory.legal: true,
    ServiceCategory.counseling: true,
    ServiceCategory.community: true,
    ServiceCategory.medical: true,
  };

  // Purple shades for different categories
  final Map<ServiceCategory, Color> _categoryColors = {
    ServiceCategory.jobs: Color(0xFF2E1A6F),// Pale Purple
    ServiceCategory.shelter: Color(0xFF520F67),    // Deep Purple
    ServiceCategory.crisis: Color(0xFF9C4DCC),     // Medium Purple
    ServiceCategory.legal: Color(0xFFA86DD9),      // Light Purple
    ServiceCategory.counseling: Color(0xFFB384E6),  // Lavender Purple
    ServiceCategory.community: Color(0xFFC4A0EC),   // Soft Purple
    ServiceCategory.medical: Color(0xFFD1B2F3),
  };

  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeOrganizations();
  }

  void _initializeOrganizations() {
    _organizationsByCategory = {
      ServiceCategory.jobs: _generateOrganizationsForCategory(
        ServiceCategory.jobs,
        [
          {"name": "Career Development Center", "label": "Career Center"},
          {"name": "Skills Training Center", "label": "Job Training"},
          {"name": "Professional Development Hub", "label": "Prof Dev"},
          {"name": "Employment Resources", "label": "Employment"},
        ],
      ),
      ServiceCategory.shelter: _generateOrganizationsForCategory(
        ServiceCategory.shelter,
        [
          {"name": "Women's Safe House", "label": "Safe House A"},
          {"name": "Sisters' Shelter", "label": "Safe House B"},
          {"name": "Phoenix House", "label": "Safe House C"},
        ],
      ),
      ServiceCategory.crisis: _generateOrganizationsForCategory(
        ServiceCategory.crisis,
        [
          {"name": "24/7 Crisis Support Center", "label": "Crisis Center"},
          {"name": "Emergency Response Team", "label": "Emergency Support"},
          {"name": "Immediate Help Network", "label": "Crisis Network"},
        ],
      ),
      ServiceCategory.legal: _generateOrganizationsForCategory(
        ServiceCategory.legal,
        [
          {"name": "Women's Rights Legal Center", "label": "Legal Aid"},
          {"name": "Domestic Violence Legal Aid", "label": "DV Legal"},
          {"name": "Family Protection Law Office", "label": "Family Law"},
        ],
      ),
      ServiceCategory.counseling: _generateOrganizationsForCategory(
        ServiceCategory.counseling,
        [
          {"name": "Trauma Recovery Center", "label": "Recovery Center"},
          {"name": "Women's Counseling Services", "label": "Counseling"},
          {"name": "Healing Together Network", "label": "Support Group"},
        ],
      ),
      ServiceCategory.community: _generateOrganizationsForCategory(
        ServiceCategory.community,
        [
          {"name": "Women's Community Center", "label": "Community Hub"},
          {"name": "Sisters Supporting Sisters", "label": "Support Network"},
          {"name": "Empowerment Alliance", "label": "Alliance"},
        ],
      ),
      ServiceCategory.medical: _generateOrganizationsForCategory(
        ServiceCategory.medical,
        [
          {"name": "Women's Health Center", "label": "Health Center"},
          {"name": "Trauma Care Clinic", "label": "Medical Care"},
          {"name": "Wellness Support Center", "label": "Wellness"},
        ],
      ),

    };
  }

  List<Organization> _generateOrganizationsForCategory(
      ServiceCategory category,
      List<Map<String, String>> nameLabels,
      ) {
    return nameLabels.map((nameLabel) {
      return Organization(
        name: nameLabel["name"]!,
        homeLabel: nameLabel["label"]!,
        contact: "+1 (${_random.nextInt(900) + 100}) ${_random.nextInt(900) + 100}-${_random.nextInt(9000) + 1000}",
        hours: "24/7 Confidential Support",
        address: "${_random.nextInt(999) + 1} ${_getRandomStreet()}",
        description: _getDescriptionForCategory(category),
        category: category,
        position: vmath.Vector2(
          _random.nextDouble() * (mapWidth - 100) + 50,
          _random.nextDouble() * (mapHeight - 100) + 50,
        ),
        color: _categoryColors[category]!,
      );
    }).toList();
  }

  String _getRandomStreet() {
    final streets = [
      "Hope Street",
      "Safety Lane",
      "Freedom Road",
      "Peace Avenue",
      "Unity Drive",
    ];
    return streets[_random.nextInt(streets.length)];
  }

  String _getDescriptionForCategory(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.shelter:
      case ServiceCategory.jobs:
        return "Employment resources, job training, career counseling, and professional development programs.";
        return "Confidential emergency shelter providing safe housing and support services for women and children fleeing abuse.";
      case ServiceCategory.crisis:
        return "24/7 emergency response and crisis intervention services for women in immediate need of assistance.";
      case ServiceCategory.legal:
        return "Free legal advocacy and representation for domestic violence survivors, including protection orders and family law.";
      case ServiceCategory.counseling:
        return "Trauma-informed counseling and therapy services, supporting women through their healing journey.";
      case ServiceCategory.community:
        return "Community-based support services and advocacy, connecting women with resources and peer support networks.";
      case ServiceCategory.medical:
        return "Confidential medical care and health services specialized for women affected by abuse and trauma.";

    }
  }

  String _getCategoryName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.jobs:
        return 'Jobs & Training';
      case ServiceCategory.shelter:
        return 'Safe Houses';
      case ServiceCategory.crisis:
        return 'Crisis Support';
      case ServiceCategory.legal:
        return 'Legal Aid';
      case ServiceCategory.counseling:
        return 'Counseling';
      case ServiceCategory.community:
        return 'Community';
      case ServiceCategory.medical:
        return 'Medical';

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(),
            if (_selectedOrg != null) _buildInfoCard(),
            _buildCategoryFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size screenSize = MediaQuery.of(context).size;
        final double scaleX = screenSize.width / mapWidth;
        final double scaleY = screenSize.height / mapHeight;
        final double baseScale = math.max(scaleX, scaleY);

        return GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: (details) => _handleScaleUpdate(details, baseScale),
          child: Container(
            color: Colors.grey[200],
            child: Stack(
              children: [
                Positioned(
                  left: _offset.dx,
                  top: _offset.dy,
                  child: Transform.scale(
                    scale: _scale,
                    alignment: Alignment.topLeft,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/map.jpeg',
                          width: mapWidth,
                          height: mapHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: mapWidth,
                              height: mapHeight,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('Map image not found'),
                              ),
                            );
                          },
                        ),
                        ..._buildMarkers(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedOrg!.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedOrg!.homeLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedOrg!.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedOrg = null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Contact: ${_selectedOrg!.contact}'),
              Text('Hours: ${_selectedOrg!.hours}'),
              Text('Address: ${_selectedOrg!.address}'),
              const SizedBox(height: 8),
              Text(
                _selectedOrg!.description,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ServiceCategory.values.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  selected: _categoryVisibility[category]!,
                  label: Text(_getCategoryName(category)),
                  labelStyle: TextStyle(
                    color: _categoryVisibility[category]! ? Colors.white : Colors.black,
                  ),
                  selectedColor: _categoryColors[category],
                  onSelected: (bool selected) {
                    setState(() {
                      _categoryVisibility[category] = selected;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMarkers() {
    List<Widget> markers = [];

    _categoryVisibility.forEach((category, isVisible) {
      if (isVisible) {
        for (var org in _organizationsByCategory[category]!) {
          markers.add(
            Positioned(
              left: org.position.x,
              top: org.position.y,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedOrg = org),
                    child: Icon(
                      Icons.location_on,
                      color: org.color,
                      size: 30 * _scale.clamp(0.8, 1.5),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: org.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      org.homeLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * _scale.clamp(0.8, 1.2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    return markers;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _startFocalPoint = details.focalPoint;
    _previousOffset = _offset;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, double baseScale) {
    setState(() {
      // Update scale with limits
      _scale = (_previousScale * details.scale).clamp(baseScale, 4.0);

      // Calculate new offset relative to top-left origin
      final Offset delta = details.focalPoint - _startFocalPoint;
      _offset = _previousOffset + delta;

      // Apply bounds
      _clampOffset();
    });
  }

  void _clampOffset() {
    final Size screenSize = MediaQuery.of(context).size;
    final double scaledWidth = mapWidth * _scale;
    final double scaledHeight = mapHeight * _scale;

    final double minX = -(scaledWidth - screenSize.width);
    final double minY = -(scaledHeight - screenSize.height);

    _offset = Offset(
      _offset.dx.clamp(minX, 0),
      _offset.dy.clamp(minY, 0),
    );
  }
}