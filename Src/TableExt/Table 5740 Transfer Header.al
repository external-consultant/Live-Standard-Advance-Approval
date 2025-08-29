tableextension 80931 TableExt5740 extends "Transfer Header"
{
    fields
    {
        field(80930; "Approval Status 2"; Option)
        {
            Caption = 'Approval Status 2';
            DataClassification = ToBeClassified;
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval,Pending Prepayment';
            OptionMembers = Open,Released,"Pending Approval","Pending Prepayment";
        }
        //T12141-NS
        field(80950; "First Approval Completed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'First Approval Completed';
        }
        field(80951; "Workflow Category Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Workflow Category Type';
        }
        //T12141-NE
    }
}