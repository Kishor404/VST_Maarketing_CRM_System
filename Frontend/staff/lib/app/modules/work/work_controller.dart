import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:convert';

import '../../data/models/service_model.dart';
import '../../data/providers/service_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/snackbar.dart';

class WorkController extends GetxController {
  final ServiceProvider _provider = ServiceProvider(ApiClient());

  final assignedServices = <ServiceModel>[].obs;
  final completedServices = <ServiceModel>[].obs;

  final selectedService = Rxn<ServiceModel>();

  /// Loading states
  final loading = false.obs;
  final detailLoading = false.obs;
  final otpLoading = false.obs;

  final workDetail = ''.obs;
  final amountCharged = ''.obs;
  final otp = ''.obs;
  final partsReplaced = <Map<String, String>>[].obs;

  final phone = ''.obs;

  var jobCards = <Map<String, dynamic>>[].obs;

  final serviceImage = Rx<File?>(null);

  final devOtp = ''.obs; // ⚠️ DEV ONLY


  

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  /// ============================
  /// Load Assigned + Completed
  /// ============================
  Future<void> loadAll() async {
    try {
      loading.value = true;

      final results = await Future.wait([
        _provider.getAssignedServices(),
        _provider.getCompletedServices(),
      ]);

      assignedServices.assignAll(results[0]);
      completedServices.assignAll(results[1]);
    } catch (e) {
      AppSnackbar.error(
        title: "Work Error",
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }

  

  /// ============================
  /// Service Detail
  /// ============================
  Future<void> loadDetail(int id) async {
    try {
      detailLoading.value = true;
      selectedService.value =
          await _provider.getServiceDetail(id);
    } catch (e) {
      AppSnackbar.error(
        title: "Detail Error",
        message: e.toString(),
      );
    } finally {
      detailLoading.value = false;
    }
  }

  /// ============================
  /// OTP Request
  /// ============================
  Future<void> requestOtp(int serviceId) async {
    if (phone.value.length != 10) {
      AppSnackbar.error(
        title: "Invalid Phone",
        message: "Enter a valid 10-digit phone number",
      );
      return;
    }

    try {
      otpLoading.value = true;

      final fullPhone = "+91${phone.value}";

      final otpFromApi = await _provider.requestOtp(
        serviceId,
        phone: fullPhone,
      );

      // DEV ONLY
      if (otpFromApi != null) {
        devOtp.value = otpFromApi;
      }


      AppSnackbar.success(
        title: "OTP Sent",
        message: "OTP sent to $fullPhone",
      );
    } catch (e) {
      AppSnackbar.error(
        title: "OTP Error",
        message: e.toString(),
      );
    } finally {
      otpLoading.value = false;
    }
  }


  /// ============================
  /// Complete Service
  /// ============================
  Future<void> completeService({
    required int serviceId,
    required String otp,
    required Map<String, dynamic> payload,
  }) async {
    try {
      otpLoading.value = true;

      /// ======================
      /// Create Multipart Form
      /// ======================

      dio.FormData formData = dio.FormData.fromMap({});

      formData.fields.add(MapEntry("otp", otp));

      formData.fields.add(
        MapEntry("work_detail", payload["work_detail"]),
      );

      formData.fields.add(
        MapEntry(
          "amount_charged",
          payload["amount_charged"].toString(),
        ),
      );

      /// PARTS REPLACED
      formData.fields.add(
        MapEntry(
          "parts_replaced",
          jsonEncode(
            partsReplaced.map((part) {
              return {
                "name": part["name"] ?? "",
                "serial_number": part["serial"] ?? "",
              };
            }).toList(),
          ),
        ),
      );

      /// JOB CARDS
      for (int i = 0; i < jobCards.length; i++) {
        final jc = jobCards[i];

        formData.fields.add(
          MapEntry("job_cards[$i][part_name]", jc["part_name"] ?? ""),
        );

        formData.fields.add(
          MapEntry("job_cards[$i][details]", jc["details"] ?? ""),
        );

        formData.fields.add(
          MapEntry("job_cards[$i][serial_number]", jc["serial_number"] ?? ""),
        );

        /// IMAGE UPLOAD
        if (jc["image"] != null && jc["image"] is File) {
          formData.files.add(
            MapEntry(
              "job_cards[$i][image]",
              await dio.MultipartFile.fromFile(
                jc["image"].path,
                filename: jc["image"].path.split('/').last,
              ),
            ),
          );
        }
      }
      /// SERVICE IMAGE
      if (serviceImage.value != null) {
        debugPrint("SERVICE IMAGE: ${serviceImage.value}");
        formData.files.add(
          MapEntry(
            "image",  // 🔥 IMPORTANT: backend expects this key
            await dio.MultipartFile.fromFile(
              serviceImage.value!.path,
              filename: serviceImage.value!.path.split('/').last,
            ),
          ),
        );
      } 

      for (var file in formData.files) {
        debugPrint("FILE → ${file.key} : ${file.value.filename}");
      }

      /// ======================
      /// API CALL
      /// ======================
      /// 
      for (var field in formData.fields) {
        debugPrint("${field.key} : ${field.value}");
      }

      await _provider.verifyOtpAndCompleteMultipart(
        serviceId: serviceId,
        formData: formData,
      );

      /// RESET STATE
      selectedService.value = null;
      workDetail.value = '';
      amountCharged.value = '';
      devOtp.value = '';
      this.otp.value = '';
      partsReplaced.clear();
      jobCards.clear();
      serviceImage.value = null;

      await loadAll();

      Get.back();
      Get.back();

      AppSnackbar.success(
        title: "Completed",
        message: "Service completed successfully",
      );

    } catch (e) {
      AppSnackbar.error(
        title: "Completion Failed",
        message: e.toString(),
      );
    } finally {
      otpLoading.value = false;
    }
  }



  int get assignedCount => assignedServices.length;

}
