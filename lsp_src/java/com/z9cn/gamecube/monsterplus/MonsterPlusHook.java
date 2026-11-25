package com.z9cn.gamecube.monsterplus;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XC_MethodReplacement;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

public class MonsterPlusHook implements IXposedHookLoadPackage {
    private static final String TAG = "[GameCubeZ9Monster+] ";

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lpparam) {
        if (lpparam == null || !"com.vivo.gamecube".equals(lpparam.packageName)) {
            return;
        }
        ClassLoader cl = lpparam.classLoader;
        int hooked = 0;

        // 1. Hook backClipConnectState getter/setter (i9.a) -> always report cooling clip connected
        try {
            XposedHelpers.findAndHookMethod("i9.a", cl, "a",
                XC_MethodReplacement.returnConstant(Boolean.TRUE));
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip i9.a#a: " + t);
        }

        try {
            XposedHelpers.findAndHookMethod("i9.a", cl, "f", boolean.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        param.args[0] = Boolean.TRUE;
                    }
                });
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip i9.a#f: " + t);
        }

        // 2. Hook ModeShiftBar#y(boolean) -> always render Monster+ mode button
        try {
            XposedHelpers.findAndHookMethod(
                "com.vivo.gameassistant.homegui.sideslide.panels.performance.modeshift.ModeShiftBar",
                cl, "y", boolean.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        param.args[0] = Boolean.TRUE;
                    }
                });
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip ModeShiftBar#y: " + t);
        }

        // 3. Hook Monster+ platform support flags in com.vivo.common.a (M0 / Y / N0)
        String[] flagMethods = new String[] { "M0", "Y", "N0" };
        for (String m : flagMethods) {
            try {
                XposedHelpers.findAndHookMethod("com.vivo.common.a", cl, m,
                    XC_MethodReplacement.returnConstant(Boolean.TRUE));
                hooked++;
            } catch (Throwable t) {
                XposedBridge.log(TAG + "skip com.vivo.common.a#" + m + ": " + t);
            }
        }

        // 4. Unlock Esports / Competition Mode & Game Audio for ALL games in Game Space
        //    (CN ROM leaves competition_mode blank for com.garena.game.kgvn)
        try {
            XposedHelpers.findAndHookMethod("com.vivo.gameassistant.utils.z0", cl, "I0",
                XC_MethodReplacement.returnConstant(Boolean.TRUE));
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip z0#I0: " + t);
        }

        try {
            XposedHelpers.findAndHookMethod("com.vivo.gameassistant.utils.z0", cl, "T0",
                XC_MethodReplacement.returnConstant(Boolean.TRUE));
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip z0#T0: " + t);
        }

        try {
            XposedHelpers.findAndHookMethod("com.vivo.gameassistant.utils.z0", cl, "y0",
                String.class, XC_MethodReplacement.returnConstant(Boolean.TRUE));
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip z0#y0: " + t);
        }

        try {
            Class<?> funcCls = cl.loadClass("com.vivo.common.supportlist.pojo.ConfiguredFunction");
            XposedHelpers.findAndHookMethod("com.vivo.gameassistant.utils.z0", cl, "s0",
                funcCls, String.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        if (param.args == null || param.args.length < 1 || param.args[0] == null) {
                            return;
                        }
                        String name = String.valueOf(param.args[0]);
                        if ("COMPETITION_MODE".equals(name)
                                || "GAME_MANIPULATION_COMPETITION_PARAM".equals(name)
                                || "SUPER_AUDIO".equals(name)
                                || "GAME_CUSTOM_SOUND_FOR_VERSION_1".equals(name)
                                || "GAME_CUSTOM_SOUND_FOR_VERSION_2".equals(name)) {
                            param.setResult(Boolean.TRUE);
                        }
                    }
                });
            hooked++;
        } catch (Throwable t) {
            XposedBridge.log(TAG + "skip z0#s0: " + t);
        }

        XposedBridge.log(TAG + "Active in " + lpparam.processName + " (hooks=" + hooked + ")");
    }
}
