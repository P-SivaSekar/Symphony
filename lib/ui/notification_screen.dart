import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/notification_model.dart';
import '../services/player_service.dart';
import 'package:intl/intl.dart';
import 'yt_music_player.dart';
import '../utils/play_helper.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    final notifications = appProvider.notifications;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
              onPressed: () {
                appProvider.clearAllNotifications();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? null : theme.scaffoldBackgroundColor,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.black,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
          ),
          SafeArea(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: textColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isGlobal = notification.userId == 'global';
                      final isRead = isGlobal
                          ? notification.readBy.contains(appProvider.user?.uid)
                          : notification.isRead;

                      return Dismissible(key: Key(notification.id), direction: DismissDirection.endToStart, background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red.withOpacity(0.8), margin: const EdgeInsets.only(bottom: 12), child: const Icon(Icons.delete, color: Colors.white)), onDismissed: (direction) { appProvider.markNotificationAsRead(notification); }, child: GestureDetector(
                        onTap: () {
                          if (!isRead) {
                            appProvider.markNotificationAsRead(notification);
                          }
                          // If notification has a songId, play that song
                          if (notification.songId != null &&
                              notification.songId!.isNotEmpty) {
                            final song = appProvider.allSongs.where(
                              (s) => s.id == notification.songId,
                            );
                            if (song.isNotEmpty) {
                              playAndOpenPlayer(
                                  context, [song.first], 0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Now playing: ${song.first.title}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? (isDark
                                      ? Colors.white10
                                      : Colors.black.withOpacity(0.05))
                                : (primaryColor.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? Colors.transparent
                                  : primaryColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isGlobal
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isGlobal
                                      ? Icons.music_note
                                      : Icons.check_circle_outline,
                                  color: isGlobal
                                      ? Colors.blueAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification.title,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM d, h:mm a',
                                              ).format(notification.timestamp),
                                              style: TextStyle(
                                                color: textColor.withOpacity(0.5),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent.withOpacity(0.7)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                appProvider.markNotificationAsRead(notification);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(
                                    top: 18,
                                    left: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ));
                    },
                  ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: YTMusicPlayer(hasBottomNav: false),
          ),
        ],
      ),
    );
  }
}


