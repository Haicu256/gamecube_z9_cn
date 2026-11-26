import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

public class GcTouchDb {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: GcTouchDb <sync|clear|list> <db_path> [pkg ...]");
            System.exit(2);
        }
        String cmd = args[0];
        String dbPath = args[1];
        SQLiteDatabase db = null;
        try {
            db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READWRITE);
            if ("list".equals(cmd)) {
                Cursor c = db.rawQuery(
                    "SELECT pkg_name, channel FROM game_dimen WHERE function='game_manipulation_touch' AND channel='*'",
                    null
                );
                if (c != null) {
                    while (c.moveToNext()) {
                        System.out.println(c.getString(0) + "|" + c.getString(1));
                    }
                    c.close();
                }
            } else if ("sync".equals(cmd)) {
                int added = 0;
                db.beginTransaction();
                try {
                    for (int i = 2; i < args.length; i++) {
                        String pkg = args[i];
                        if (pkg == null || pkg.isEmpty()) continue;
                        boolean exists = false;
                        Cursor c = db.rawQuery(
                            "SELECT 1 FROM game_dimen WHERE function='game_manipulation_touch' AND pkg_name=? LIMIT 1",
                            new String[]{pkg}
                        );
                        if (c != null) {
                            exists = c.moveToFirst();
                            c.close();
                        }
                        if (!exists) {
                            db.execSQL(
                                "INSERT INTO game_dimen (function, type, pkg_name, label, channel, oversea, game_index, support_sdk, frame_inter_value) " +
                                "VALUES ('game_manipulation_touch', 'white', ?, ?, '*', 0, -1, 0, -1)",
                                new Object[]{pkg, pkg}
                            );
                            System.out.println("ADDED:" + pkg);
                            added++;
                        }
                    }
                    db.setTransactionSuccessful();
                } finally {
                    db.endTransaction();
                }
                if (added > 0) {
                    Cursor cp = db.rawQuery("PRAGMA wal_checkpoint(TRUNCATE)", null);
                    if (cp != null) cp.close();
                }
                System.out.println("SYNC_DONE:" + added);
            } else if ("clear".equals(cmd)) {
                int removed = 0;
                db.beginTransaction();
                try {
                    for (int i = 2; i < args.length; i++) {
                        String pkg = args[i];
                        if (pkg == null || pkg.isEmpty()) continue;
                        boolean exists = false;
                        Cursor c = db.rawQuery(
                            "SELECT 1 FROM game_dimen WHERE function='game_manipulation_touch' AND channel='*' AND pkg_name=? LIMIT 1",
                            new String[]{pkg}
                        );
                        if (c != null) {
                            exists = c.moveToFirst();
                            c.close();
                        }
                        if (exists) {
                            db.execSQL(
                                "DELETE FROM game_dimen WHERE function='game_manipulation_touch' AND channel='*' AND pkg_name=?",
                                new Object[]{pkg}
                            );
                            System.out.println("REMOVED:" + pkg);
                            removed++;
                        }
                    }
                    db.setTransactionSuccessful();
                } finally {
                    db.endTransaction();
                }
                if (removed > 0) {
                    Cursor cp = db.rawQuery("PRAGMA wal_checkpoint(TRUNCATE)", null);
                    if (cp != null) cp.close();
                }
                System.out.println("CLEAR_DONE:" + removed);
            } else {
                System.err.println("Unknown cmd: " + cmd);
                System.exit(2);
            }
        } catch (Throwable t) {
            System.err.println("ERR:" + t.toString());
            System.exit(1);
        } finally {
            if (db != null) {
                try { db.close(); } catch (Throwable ignored) {}
            }
        }
    }
}
