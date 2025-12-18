import 'dart:io';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/provider_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/provider_job_offering_card.dart';
import 'MySkillProvider.dart';

class ProviderMySkillScreen extends StatefulWidget {
  const ProviderMySkillScreen({super.key});

  @override
  State<ProviderMySkillScreen> createState() => _ProviderMySkillScreenState();
}

class _ProviderMySkillScreenState extends State<ProviderMySkillScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch skills when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MySkillProvider>(context, listen: false).fetchSkills();
    });
  }

  void _showEditBottomSheet(BuildContext context, Skill skill) {
    final formKey = GlobalKey<FormState>();
    final skillNameController = TextEditingController(text: skill.skillName ?? '');
    final serviceNameController = TextEditingController(text: skill.serviceName ?? '');
    final experienceController = TextEditingController(text: skill.experience ?? '');
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Skill',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Skill Name
                      TextFormField(
                        controller: skillNameController,
                        decoration: InputDecoration(
                          labelText: 'Skill Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter skill name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Service Name
                      TextFormField(
                        controller: serviceNameController,
                        decoration: InputDecoration(
                          labelText: 'Service Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter service name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Experience
                      TextFormField(
                        controller: experienceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Experience (years)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter experience';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Proof Document
                      Text(
                        'Proof Document',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );

                          if (image != null) {
                            setModalState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select new proof document',
                                style: TextStyle(color: Colors.grey),
                              ),
                              if (skill.proofDocument != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Current: ${skill.proofDocument!.split('/').last}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Update Button
                      Consumer<MySkillProvider>(
                        builder: (context, skillProvider, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: skillProvider.isLoading
                                  ? null
                                  : () async {
                                if (formKey.currentState!.validate()) {
                                  if (skill.id == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Invalid skill ID'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final success = await skillProvider.updateSkill(
                                    skillId: skill.id!,
                                    skillName: skillNameController.text.trim(),
                                    serviceName: serviceNameController.text.trim(),
                                    experience: experienceController.text.trim(),
                                    proofDocument: selectedImage,
                                  );

                                  if (success && mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Skill updated successfully'),
                                        backgroundColor: ColorConstant.moyoGreen,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          skillProvider.errorMessage ??
                                              'Failed to update skill',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstant.moyoGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: skillProvider.isLoading
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                'Update Skill',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProviderOnlyTitleAppbar(title: "Work Offerings"),
      backgroundColor: ColorConstant.scaffoldGray,
      body: Consumer<MySkillProvider>(
        builder: (context, skillProvider, child) {
          if (skillProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (skillProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    skillProvider.errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => skillProvider.fetchSkills(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (skillProvider.skills.isEmpty) {
            return Center(
              child: Text(
                'No job offerings found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => skillProvider.fetchSkills(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: skillProvider.skills.length,
              itemBuilder: (context, index) {
                final skill = skillProvider.skills[index];
                final isRejected = skill.status?.toLowerCase() == 'rejected';

                return ProviderJobOfferingCard(
                  subCat: skill.skillName ?? 'Unknown Skill',
                  verified: skill.status?.toLowerCase() == 'approved',
                  serviceName: skill.serviceName,
                  experience: skill.experience,
                  status: skill.status,
                  isChecked: skill.isChecked ?? false,
                  showEditButton: isRejected,
                  onEdit: isRejected
                      ? () => _showEditBottomSheet(context, skill)
                      : null,
                  onToggle: (value) async {
                    if (skill.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid skill ID'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Call the API to update skill status
                    final success = await skillProvider
                        .updateSkillCheckedStatus(skill.id!, value);

                    if (!success && mounted) {
                      // Show error message if update failed
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            skillProvider.errorMessage ??
                                'Failed to update skill status',
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      // Refresh to get the correct state from server
                      await skillProvider.fetchSkills();
                    } else if (success && mounted) {
                      // Optional: Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Skill status updated successfully'),
                          backgroundColor: ColorConstant.moyoGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}