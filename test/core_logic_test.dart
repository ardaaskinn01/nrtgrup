import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrt/core/constants/app_constants.dart';
import 'package:nrt/core/utils/formatters.dart';
import 'package:nrt/core/widgets/mood_burst.dart';
import 'package:nrt/models/attendance_record.dart';
import 'package:nrt/models/debt.dart';
import 'package:nrt/models/receivable.dart';

void main() {
  group('Alacak Bakiye Hesabı (ReceivableEntry.calculateBalance)', () {
    test('Alacak ekleme ve kısmi tahsilat sonrası kalan bakiyeyi doğru hesaplar', () {
      final now = DateTime(2026, 11, 24);
      final entries = [
        ReceivableEntry(
          type: ReceivableEntryType.alacakEkle,
          amount: 15000,
          date: now,
          createdAt: now,
        ),
        ReceivableEntry(
          type: ReceivableEntryType.alacakEkle,
          amount: 5000,
          date: now,
          createdAt: now,
        ),
        ReceivableEntry(
          type: ReceivableEntryType.tahsilat,
          amount: 7500,
          date: now,
          createdAt: now,
        ),
      ];

      expect(ReceivableEntry.calculateBalance(entries), 12500.0);
    });

    test('Tam tahsilat yapıldığında bakiye 0 olur', () {
      final now = DateTime(2026, 11, 24);
      final entries = [
        ReceivableEntry(
          type: ReceivableEntryType.alacakEkle,
          amount: 10000,
          date: now,
          createdAt: now,
        ),
        ReceivableEntry(
          type: ReceivableEntryType.tahsilat,
          amount: 10000,
          date: now,
          createdAt: now,
        ),
      ];

      expect(ReceivableEntry.calculateBalance(entries), 0.0);
    });
  });

  group('Borç Bakiye Hesabı (DebtEntry.calculateBalance)', () {
    test('Borç ekleme ve kısmi ödeme sonrası kalan borcu doğru hesaplar', () {
      final now = DateTime(2026, 11, 24);
      final entries = [
        DebtEntry(
          type: DebtEntryType.borcEkle,
          amount: 25000,
          date: now,
          createdAt: now,
        ),
        DebtEntry(
          type: DebtEntryType.odeme,
          amount: 8000,
          date: now,
          createdAt: now,
        ),
        DebtEntry(
          type: DebtEntryType.borcEkle,
          amount: 3000,
          date: now,
          createdAt: now,
        ),
      ];

      expect(DebtEntry.calculateBalance(entries), 20000.0);
    });
  });

  group('50.000 TL Animasyon Eşiği (MoodBurst.resolve)', () {
    test('Gelir < 50.000 TL için azmutlu.jpeg ve N. Tutak Mutlu döner', () {
      final res = MoodBurst.resolve(amount: 49999.99, isIncome: true);
      expect(res.type, MoodType.slightlyHappy);
      expect(res.assetPath, AppConstants.iconAzMutlu);
      expect(res.label, 'N. Tutak Mutlu');
    });

    test('Gelir == 50.000 TL (tam sınır) için mutlu.jpeg ve N. Tutak Çok Mutlu döner', () {
      final res = MoodBurst.resolve(amount: 50000.0, isIncome: true);
      expect(res.type, MoodType.happy);
      expect(res.assetPath, AppConstants.iconMutlu);
      expect(res.label, 'N. Tutak Çok Mutlu');
    });

    test('Gelir > 50.000 TL için mutlu.jpeg ve N. Tutak Çok Mutlu döner', () {
      final res = MoodBurst.resolve(amount: 120000.0, isIncome: true);
      expect(res.type, MoodType.happy);
      expect(res.assetPath, AppConstants.iconMutlu);
      expect(res.label, 'N. Tutak Çok Mutlu');
    });

    test('Her gider işlemi tutardan bağımsız mutsuz.jpeg ve N. Tutak Mutsuz döner', () {
      final resSmall = MoodBurst.resolve(amount: 100.0, isIncome: false);
      final resLarge = MoodBurst.resolve(amount: 80000.0, isIncome: false);

      expect(resSmall.type, MoodType.sad);
      expect(resSmall.assetPath, AppConstants.iconMutsuz);
      expect(resSmall.label, 'N. Tutak Mutsuz');

      expect(resLarge.type, MoodType.sad);
      expect(resLarge.assetPath, AppConstants.iconMutsuz);
      expect(resLarge.label, 'N. Tutak Mutsuz');
    });
  });

  group('Personel Çalışma Süresi Fark Hesabı', () {
    test('Normal giriş-çıkış süresi dakika cinsinden doğru hesaplanır', () {
      final duration = AttendanceRecord.calculateDurationMinutes(
        const TimeOfDay(hour: 8, minute: 30),
        const TimeOfDay(hour: 18, minute: 0),
      );
      expect(duration, 570); // 9 saat 30 dk
      expect(AppFormatters.formatDurationMinutes(duration), '9 saat 30 dk');
    });

    test('Çıkış girişten önce veya eşit ise <= 0 döner', () {
      final before = AttendanceRecord.calculateDurationMinutes(
        const TimeOfDay(hour: 18, minute: 0),
        const TimeOfDay(hour: 8, minute: 30),
      );
      final equal = AttendanceRecord.calculateDurationMinutes(
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 9, minute: 0),
      );
      expect(before, lessThan(0));
      expect(equal, 0);
    });

    test('Türkçe tutar ayrıştırma doğru çalışır', () {
      expect(AppFormatters.parseAmount('1.250,50'), 1250.50);
      expect(AppFormatters.parseAmount('50000'), 50000.0);
      expect(AppFormatters.parseAmount('₺ 750,25'), 750.25);
    });
  });
}
