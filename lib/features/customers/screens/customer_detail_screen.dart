import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/modern_cards.dart';
import '../../../models/customer.dart';
import '../providers/customer_providers.dart';
import '../repositories/customer_repository.dart';
import '../widgets/add_customer_modal.dart';
import '../widgets/add_note_modal.dart';
import '../widgets/add_work_photo_dialog.dart';
import '../widgets/photo_viewer_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama başlatılamadı')),
      );
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '9$digits';
    } else if (!digits.startsWith('90') && digits.length == 10) {
      digits = '90$digits';
    }
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp açılamadı')),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryOrange),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.pop(ctx);
                AddWorkPhotoDialog.pickAndUpload(
                  context,
                  customerId: widget.customerId,
                  source: ImageSource.camera,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryOrange),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                AddWorkPhotoDialog.pickAndUpload(
                  context,
                  customerId: widget.customerId,
                  source: ImageSource.gallery,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));

    return customerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Müşteri Detayı')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Müşteri Detayı')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Bilgiler Yüklenemedi',
          subtitle: '$err',
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Müşteri Detayı')),
            body: const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Müşteri Bulunamadı',
              subtitle: 'Bu müşteri kaydı silinmiş olabilir.',
            ),
          );
        }

        final isPhotoTab = _tabController.index == 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Müşteriyi Düzenle',
                onPressed: () => AddCustomerModal.show(context, initialCustomer: customer),
              ),
            ],
          ),
          floatingActionButton: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
              child: FloatingActionButton.extended(
                onPressed: isPhotoTab
                    ? _showPhotoSourceSheet
                    : () => AddNoteModal.show(context, customerId: widget.customerId),
                icon: Icon(isPhotoTab ? Icons.add_a_photo_outlined : Icons.note_add_outlined),
                label: Text(isPhotoTab ? 'İş Fotoğrafı Ekle' : 'Not Ekle'),
              ),
            ),
          ),
          body: Column(
            children: [
              // Üst Müşteri Kartı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: HeroGradientCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconSquircle(
                            color: AppTheme.primaryOrangeLight,
                            text: customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'M',
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: const TextStyle(
                                    color: AppTheme.pureWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (customer.phone.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    customer.phone,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (customer.workSummary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            customer.workSummary,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ),
                      ],
                      if (customer.phone.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.pureWhite,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                                onPressed: () => _callPhone(customer.phone),
                                icon: const Icon(Icons.phone_outlined, size: 17),
                                label: const Text('Ara'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4ADE80),
                                  backgroundColor: AppTheme.successColor.withValues(alpha: 0.14),
                                  side: const BorderSide(color: Color(0xFF22C55E), width: 1.1),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                                onPressed: () => _openWhatsApp(customer.phone),
                                icon: const Icon(Icons.chat_outlined, size: 17),
                                label: const Text('WhatsApp'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sekmeler
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryOrange,
                labelColor: AppTheme.primaryOrange,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.photo_library_outlined),
                    text: 'Yapılan İşler & Ürünler',
                  ),
                  Tab(
                    icon: Icon(Icons.notes_outlined),
                    text: 'İş Notları',
                  ),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _WorkPhotosTab(customerId: widget.customerId),
                    _WorkNotesTab(customerId: widget.customerId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkPhotosTab extends ConsumerWidget {
  final String customerId;

  const _WorkPhotosTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(customerPhotosProvider(customerId));

    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Fotoğraflar Yüklenemedi',
        subtitle: '$err',
      ),
      data: (photos) {
        if (photos.isEmpty) {
          return const EmptyState(
            icon: Icons.add_photo_alternate_outlined,
            title: 'Henüz İş Fotoğrafı Yok',
            subtitle: 'Bu müşteriye yapılan ürünleri ve montajları eklemek için alttaki butona dokunun.',
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return SurfaceCard(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              onTap: () => PhotoViewerScreen.show(
                context,
                photo: photo,
                onDelete: () => _deletePhoto(context, ref, photo),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 36),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => _deletePhoto(context, ref, photo),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.description,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatDate(photo.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: AdaptiveColors.orange(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    CustomerWorkPhoto photo,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'İş Fotoğrafını Sil',
      message: '"${photo.description}" fotoğrafını kalıcı olarak silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(customerRepositoryProvider).deleteWorkPhoto(customerId, photo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş fotoğrafı silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class _WorkNotesTab extends ConsumerWidget {
  final String customerId;

  const _WorkNotesTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(customerNotesProvider(customerId));

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Notlar Yüklenemedi',
        subtitle: '$err',
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return const EmptyState(
            icon: Icons.note_alt_outlined,
            title: 'Henüz İş Notu Yok',
            subtitle: 'Ölçü, malzeme kodu veya özel istekleri kaydetmek için alttaki butona dokunun.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 96),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final orange = AdaptiveColors.orange(context);
            return SurfaceCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              leftAccentColor: orange,
              onTap: () => AddNoteModal.show(
                context,
                customerId: customerId,
                initialNote: note,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.content,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 10),
                        StatusPill(
                          label: AppFormatters.formatLongDate(note.date),
                          color: orange,
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AdaptiveColors.subText(context),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        AddNoteModal.show(
                          context,
                          customerId: customerId,
                          initialNote: note,
                        );
                      } else if (val == 'delete') {
                        _deleteNote(context, ref, note);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    CustomerNote note,
  ) async {
    if (note.id == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'İş Notunu Sil',
      message: 'Bu iş notunu silmek istediğinize emin misiniz?',
    );
    if (!confirmed) return;

    try {
      await ref.read(customerRepositoryProvider).deleteNote(customerId, note.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş notu silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}
