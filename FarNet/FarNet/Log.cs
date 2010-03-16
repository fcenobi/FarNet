/*
FarNet plugin for Far Manager
Copyright (c) 2005 FarNet Team
*/

using System;
using System.Diagnostics;
using System.Reflection;
using System.Text.RegularExpressions;

namespace FarNet
{
	/// <summary>
	/// For internal use.
	/// </summary>
	public class Log : IDisposable
	{
		static TraceSwitch _Switch = new TraceSwitch("FarNet.Trace", "FarNet trace switch.");

		///
		public static TraceSwitch Switch { get { return _Switch; } }

		///
		public static int IndentLevel
		{
			get { return Trace.IndentLevel; }
			set { Trace.IndentLevel = value; }
		}

		///
		public static string Format(MethodInfo method)
		{
			return method.ReflectedType.FullName + "." + method.Name;
		}

		///
		public static string FormatException(Exception e)
		{
			//?? _090901_055134 Regex is used to fix bad PS V1 strings; check V2
			Regex re = new Regex("[\r\n]+");
			string info = e.GetType().Name + ":\r\n" + re.Replace(e.Message, "\r\n") + "\r\n";

			// get an error record
			if (e.GetType().FullName.StartsWith("System.Management.Automation."))
			{
				object errorRecord = Property(e, "ErrorRecord");
				if (errorRecord != null)
				{
					// process the error record
					object ii = Property(errorRecord, "InvocationInfo");
					if (ii != null)
					{
						object pm = Property(ii, "PositionMessage");
						if (pm != null)
							//?? 090517 Added Trim(), because a position message starts with an empty line
							info += re.Replace(pm.ToString().Trim(), "\r\n") + "\r\n";
					}
				}
			}

			if (e.InnerException != null)
				info += "\r\n" + FormatException(e.InnerException);

			return info;
		}

		///
		public static void TraceError(string error)
		{
			Trace.TraceError(error);
		}

		// return: null if not written or formatted error info
		///
		public static string TraceException(Exception error)
		{
			// no job?
			if (null == error || !Switch.TraceError)
				return null;

			// find the last dot
			string type = error.GetType().FullName;
			int i = type.LastIndexOf('.');

			// system error: trace as error
			string r = null;
			if (i >= 0 && type.Substring(0, i) == "System")
			{
				r = FormatException(error);
				Trace.TraceError(r);
			}
			// other error: trace as warning
			else if (Switch.TraceWarning)
			{
				r = FormatException(error);
				Trace.TraceWarning(r);
			}

			return r;
		}

		///
		public static void TraceWarning(string info)
		{
			Trace.TraceWarning(info);
		}

		///
		public static void WriteLine(string info)
		{
			Trace.WriteLine(info);
		}

		// Gets a property value by name or null
		static object Property(object obj, string name)
		{
			try
			{
				return obj.GetType().InvokeMember(name, BindingFlags.GetProperty | BindingFlags.Public | BindingFlags.Instance, null, obj, null);
			}
			catch (Exception e)
			{
				TraceException(e);
				return null;
			}
		}

		readonly int MyIndentLevel;

		///
		public Log(string info)
		{
			MyIndentLevel = Log.IndentLevel;
			Log.WriteLine(info + " {");
			Log.IndentLevel = MyIndentLevel + 1;
		}

		///
		public Log(string format, params object[] args)
		{
			MyIndentLevel = Log.IndentLevel;
			Log.WriteLine(Invariant.Format(format, args) + " {");
			Log.IndentLevel = MyIndentLevel + 1;
		}

		///
		public void Dispose()
		{
			Log.IndentLevel = MyIndentLevel;
			Log.WriteLine("}");
		}
	}
}