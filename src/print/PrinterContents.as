package print
{
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableString;
	
	public class PrinterContents implements ILinkableObject
	{
		public function PrinterContents()
		{
		}
		
		public static const timesSTART:String = '<TEXTFORMAT LEADING="2"><P ALIGN="LEFT"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">';
		public static const timesEND:String = '</FONT></P></TEXTFORMAT>';
		
		
		public static const timesRightSTART:String = '<TEXTFORMAT LEADING="2"><P ALIGN="RIGHT"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">';
		
		public static const boldSTART:String = '<B>';
		public static const boldEnd:String = '</B>';
		
		public static const italicSTART:String = '<I>';
		public static const italicEND:String = '</I>';
		
		
		
		
		public const ADDRESS:String = '<TEXTFORMAT LEADING="2"><P ALIGN="LEFT"><FONT FACE="Times New Roman" SIZE="10" COLOR="#000000" LETTERSPACING="0" KERNING="0">University Crossing, Suite 140</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="LEFT"><FONT FACE="Times New Roman" SIZE="10" COLOR="#000000" LETTERSPACING="0" KERNING="0">220 Pawtucket Street</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="LEFT"><FONT FACE="Times New Roman" SIZE="10" COLOR="#000000" LETTERSPACING="0" KERNING="0">Lowell, MA 01854</FONT></P></TEXTFORMAT>';
		
		public const CONTACT:String = '<TEXTFORMAT LEADING="2"><P ALIGN="RIGHT"><FONT FACE="Times New Roman" SIZE="10" COLOR="#000000" LETTERSPACING="0" KERNING="0">Phone: (978)934-2618</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="RIGHT"><FONT FACE="Times New Roman" SIZE="10" COLOR="#000000" LETTERSPACING="0" KERNING="0">Fax: (978)934-4018</FONT></P></TEXTFORMAT>';
		
		public const DEPARTMENT:String ='<TEXTFORMAT LEADING="2"><P ALIGN="RIGHT"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0"><B>Environmental &amp; Emergency Management</B></FONT></P></TEXTFORMAT>';		
		
		public const PARA:String ='<TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">The UMass Lowell EEM-EHS Office is pleased to announce the development and implementation of a new electronic web-based laboratory inspection program  incorporating numerous best lab practices, electronic secure filing and assessment tracking features.  A team of EEM-EHS &amp; Radiation Safety staff members will be inspecting all 300+/- laboratories at UMass Lowell on an annual basis.  Our goal is to ensure a safe work environment and compliance with federal, state, and local regulations, as well as University policies.</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0"></FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">Attached is a copy of the lab inspection report.  Please note that the inspection report only points out safety items that were corrected during the lab inspection and those requiring follow up by the lab or EEM/EHS staff.  Items that have &quot;passed&quot; the inspection will not be discussed in the lab inspection report.  All concerns should be corrected as soon as reasonably possible and/or no later than 1 month from the date the lab inspection report was received.</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0"></FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">Approximately one month after the initial inspection, the laboratory inspector will be contacting you to set up a time to conduct a follow-up inspection.  At this time, all concerns identified in the lab inspection report will be reviewed to verify corrective actions have been made.   If the items listed in the laboratory inspection report are corrected before this &quot;corrective actions due date&quot;, you may contact the laboratory inspector to set up an earlier time to meet.  All lab inspection and follow-up inspection reports will be tracked  by EEM-EHS in a database.</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0"></FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="JUSTIFY"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">EEM-EHS is excited to offer this new lab inspection program for your labs.  We know that tracking and following up on corrective actions in the labs will help to improve lab safety here at UMass Lowell!  If you have any questions regarding your lab inspection report, please contact the lab inspector at extension 42618.</FONT></P></TEXTFORMAT>';
		
		public const GREETING:String = '<TEXTFORMAT LEADING="2"><P ALIGN="LEFT"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">Sincerely,</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING="2"><P ALIGN="LEFT"><FONT FACE="Times New Roman" SIZE="12" COLOR="#000000" LETTERSPACING="0" KERNING="0">EEM-EHS Staff</FONT></P></TEXTFORMAT>'
		
		public const address:LinkableString = registerLinkableChild(this, new LinkableString(ADDRESS));
		public const contact:LinkableString = registerLinkableChild(this, new LinkableString(CONTACT));
		public const department:LinkableString = registerLinkableChild(this, new LinkableString(DEPARTMENT));
		public const para:LinkableString = registerLinkableChild(this, new LinkableString(PARA));
		public const greeting:LinkableString = registerLinkableChild(this, new LinkableString(GREETING));
		
		public const pi:LinkableString = registerLinkableChild(this, new LinkableString());
		
		public const inspector:LinkableString = registerLinkableChild(this, new LinkableString());
		
		
	}
}