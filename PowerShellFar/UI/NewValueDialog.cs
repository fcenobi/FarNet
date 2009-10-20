/*
PowerShellFar plugin for Far Manager
Copyright (C) 2006-2009 Roman Kuzmin
*/

using System;
using FarNet.Forms;

namespace PowerShellFar.UI
{
	class NewValueDialog
	{
		public IDialog Dialog;
		public IEdit Name;
		public IEdit Type;
		public IEdit Value;

		public NewValueDialog(string title)
		{
			Dialog = A.Far.CreateDialog(-1, -1, 77, 9);
			Dialog.AddBox(3, 1, 0, 0, title);
			int x = 11;

			Dialog.AddText(5, -1, 0, "&Name");
			Name = Dialog.AddEdit(x, 0, 71, string.Empty);
			Name.History = "PowerPanelNames";
			Name.UseLastHistory = true;

			Dialog.AddText(5, -1, 0, "&Type");
			Type = Dialog.AddEdit(x, 0, 71, string.Empty);
			Type.History = "PowerPanelTypes";
			Type.UseLastHistory = true;

			Dialog.AddText(5, -1, 0, "&Value");
			Value = Dialog.AddEdit(x, 0, 71, string.Empty);
			Value.History = "PowerPanelValues";
			Value.UseLastHistory = true;

			Dialog.AddText(5, -1, 0, string.Empty).Separator = 1;

			IButton buttonOK = Dialog.AddButton(0, -1, "Ok");
			buttonOK.CenterGroup = true;

			IButton buttonCancel = Dialog.AddButton(0, 0, Res.Cancel);
			buttonCancel.CenterGroup = true;
		}
	}
}
