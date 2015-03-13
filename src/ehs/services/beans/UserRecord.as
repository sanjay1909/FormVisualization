package ehs.services.beans
{
	import weave.api.newLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableString;

	//[RemoteClass(alias="ServiceLibrary.UserRecord")]
	public class UserRecord implements ILinkableObject
	{
		
		
		public const  user:LinkableString = newLinkableChild(this, LinkableString);
		public const  firstName:LinkableString = newLinkableChild(this, LinkableString);
		public const  lastName:LinkableString = newLinkableChild(this, LinkableString);
		
		public const  qualification:LinkableString = newLinkableChild(this, LinkableString);
		public const  position:LinkableString = newLinkableChild(this, LinkableString);
		
		public const  email:LinkableString = newLinkableChild(this, LinkableString);
		public const  privilege:LinkableString = newLinkableChild(this, LinkableString);
		
		public const templatePath:LinkableString = newLinkableChild(this, LinkableString);
	}
}