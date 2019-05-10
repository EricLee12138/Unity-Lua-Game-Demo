using System.Collections;
using System.Collections.Generic;
using UberLogger;

public static class LogProxy {

    private static string preprocessMessage(string message)
    {
#if UNITY_EDITOR
        if (null != LuaEngine.singleton)
        {
            message = LuaEngine.singleton.luaWhere() + message;
        }
#endif
        return message;
    }

    private static string preprocessMessage(object message) 
    {
        return preprocessMessage(message.ToString());
    }


    [StackTraceIgnore]
    public static void log(UnityEngine.Object context, string message, params object[] par)
    {
        UberDebug.Log(context, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void log(string message, params object[] par)
    {
        UberDebug.Log(preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logChannel(UnityEngine.Object context, string channel, string message, params object[] par)
    {
        UberDebug.LogChannel(context, channel, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logChannel(string channel, string message, params object[] par)
    {
        UberDebug.LogChannel(channel, preprocessMessage(message), par);
    }


    [StackTraceIgnore]
    public static void logWarning(UnityEngine.Object context, object message, params object[] par)
    {
        UberDebug.LogWarning(context, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logWarning(object message, params object[] par)
    {
        UberDebug.LogWarning(preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void LogWarningChannel(UnityEngine.Object context, string channel, string message, params object[] par)
    {
        UberDebug.LogWarningChannel(context, channel, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logWarningChannel(string channel, string message, params object[] par)
    {
        UberDebug.LogWarningChannel(channel, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logError(UnityEngine.Object context, object message, params object[] par)
    {
        UberDebug.LogError(context, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logError(object message, params object[] par)
    {
        UberDebug.LogError(preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logErrorChannel(UnityEngine.Object context, string channel, string message, params object[] par)
    {
        UberDebug.LogErrorChannel(context, channel, preprocessMessage(message), par);
    }

    [StackTraceIgnore]
    public static void logErrorChannel(string channel, string message, params object[] par)
    {
        UberDebug.LogErrorChannel(channel, preprocessMessage(message), par);
    }
}
