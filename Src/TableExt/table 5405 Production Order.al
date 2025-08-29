tableextension 80932 TblExt_80932 extends "Production Order"
{
    fields
    {
        field(80930; "Order Status"; Option)
        {
            Editable = false;
            OptionCaption = 'Open,Closed,Pending Approval,Released';
            OptionMembers = Open,Closed,"Pending Approval",Released;
        }

        field(80931; "First Approval Completed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'First Approval Completed';
        }

        field(80932; "Workflow Category Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Workflow Category Type';
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}