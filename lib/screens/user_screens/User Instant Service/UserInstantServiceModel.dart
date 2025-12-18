// Complete SubcategoryResponse.dart file - Replace your entire file with this

class SubcategoryResponse {
  final String message;
  final int total;
  final List<Subcategory> subcategories;


  SubcategoryResponse( {
    required this.message,
    required this.total,
    required this.subcategories,
  });

  factory SubcategoryResponse.fromJson(Map<String, dynamic> json) {
    return SubcategoryResponse(
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      subcategories: (json['subcategories'] as List?)
          ?.map((item) => Subcategory.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class Subcategory {
  final int id;
  final int categoryId;
  final String name;
  final String billingType;
  final String hourlyRate;
  final String dailyRate;
  final String weeklyRate;
  final String monthlyRate;
  final String icon;
  final String gst;
  final String tds;
  final String commission;
  final String createdAt;
  final String updatedAt;
  final List<ExplicitSite> explicitSite;
  final List<ImplicitSite> implicitSite;
  final List<Field> fields;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.billingType,
    required this.hourlyRate,
    required this.dailyRate,
    required this.weeklyRate,
    required this.monthlyRate,
    required this.icon,
    required this.gst,
    required this.tds,
    required this.commission,
    required this.createdAt,
    required this.updatedAt,
    required this.explicitSite,
    required this.implicitSite,
    required this.fields,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      billingType: json['billing_type'] ?? '',
      hourlyRate: json['hourly_rate'] ?? '0.00',
      dailyRate: json['daily_rate'] ?? '0.00',
      weeklyRate: json['weekly_rate'] ?? '0.00',
      monthlyRate: json['monthly_rate'] ?? '0.00',
      icon: json['icon'] ?? '',
      gst: json['gst'] ?? '0.00',
      tds: json['tds'] ?? '0.00',
      commission: json['commission'] ?? '0.00',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      explicitSite: (json['explicit_site'] as List?)
          ?.map((item) => ExplicitSite.fromJson(item))
          .toList() ??
          [],
      implicitSite: (json['implicit_site'] as List?)
          ?.map((item) => ImplicitSite.fromJson(item))
          .toList() ??
          [],
      fields: (json['fields'] as List?)
          ?.map((item) => Field.fromJson(item))
          .toList() ??
          [],
    );
  }
}

// Add these new classes to your SubcategoryResponse.dart file
class ExplicitSite {
  final String name;
  final String image;

  ExplicitSite({
    required this.name,
    required this.image,
  });

  factory ExplicitSite.fromJson(Map<String, dynamic> json) {
    return ExplicitSite(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class ImplicitSite {
  final String name;
  final String image;

  ImplicitSite({
    required this.name,
    required this.image,
  });

  factory ImplicitSite.fromJson(Map<String, dynamic> json) {
    return ImplicitSite(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }
}


// Model for dynamic fields
class Field {
  final int id;
  final int subcategoryId;
  final String fieldName;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final bool isCalculate;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  Field({
    required this.id,
    required this.subcategoryId,
    required this.fieldName,
    required this.fieldType,
    required this.options,
    required this.isRequired,
    required this.isCalculate,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'] ?? 0,
      subcategoryId: json['subcategory_id'] ?? 0,
      fieldName: json['field_name'] ?? '',
      fieldType: json['field_type'] ?? '',
      options: (json['options'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      isRequired: json['is_required'] ?? false,
      isCalculate: json['is_calculate'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}