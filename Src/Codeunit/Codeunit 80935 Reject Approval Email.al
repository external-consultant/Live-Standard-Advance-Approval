codeunit 80935 "Reject Approval Email"
{
    //   SingleInstance = true;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", OnRejectApprovalRequest, '', false, false)]
    // local procedure "Approvals Mgmt._OnRejectApprovalRequest"(var ApprovalEntry: Record "Approval Entry")
    // begin
    //     if ApprovalEntry.Status = ApprovalEntry.Status::Rejected then begin
    //         IsApprovalEntry := true;
    //         ApprovalEntry_gRec.Get(ApprovalEntry."Entry No.");
    //     end;
    // end;


    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnAfterReopenSalesDoc, '', false, false)]
    // local procedure "Release Sales Document_OnAfterReopenSalesDoc"(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; SkipWhseRequestOperations: Boolean)
    // begin

    //     if not IsApprovalEntry then
    //         exit;
    //     SendSalesRejectedMail_gFnc(SalesHeader, ApprovalEntry_gRec);

    // end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", OnAfterRejectSelectedApprovalRequest, '', false, false)]
    local procedure "Approvals Mgmt._OnAfterRejectSelectedApprovalRequest"(var ApprovalEntry: Record "Approval Entry")
    var
        SalesHeader_lRec: Record "Sales Header";
        PurchHeader_lRec: Record "Purchase Header";
        TransHeader_lRec: Record "Transfer Header";
        ServHeader_lRec: Record "Service Header";
    begin
        if ApprovalEntry.Status = ApprovalEntry.Status::Rejected then begin
            if ApprovalEntry."Table ID" = Database::"Sales Header" then begin
                SalesHeader_lRec.Get(ApprovalEntry."Document Type", ApprovalEntry."Document No.");
                SendSalesRejectedMail_gFnc(SalesHeader_lRec, ApprovalEntry);
            end;
            if ApprovalEntry."Table ID" = Database::"Purchase Header" then begin
                PurchHeader_lRec.Get(ApprovalEntry."Document Type", ApprovalEntry."Document No.");
                SendPurchaseRejectedMail_gFnc(PurchHeader_lRec, ApprovalEntry);
            end;
            if ApprovalEntry."Table ID" = Database::"Transfer Header" then begin
                TransHeader_lRec.Get(ApprovalEntry."Document No.");
                SendTransferRejectedMail_gFnc(TransHeader_lRec, ApprovalEntry);
            end;
            if ApprovalEntry."Table ID" = Database::"Service Header" then begin
                ServHeader_lRec.Get(ApprovalEntry."Document Type", ApprovalEntry."Document No.");
                SendServiceRejectMail_gFnc(ServHeader_lRec, ApprovalEntry);
            end;
        end;
    end;

    procedure SendSalesRejectedMail_gFnc(SalesHeader: Record "Sales Header"; ApprovalEntry: Record "Approval Entry")
    var
        UserSetup_lRecVar: Record "User Setup";
        // SOPrint_lRpt: Report "Sales Order Approval Request";
        SalesHeader_lRec: Record "Sales Header";
        FileName_lTxt: Text[350];
        SP_lRec: Record "Salesperson/Purchaser";
        EmailMessage_lCdu: Codeunit "Email Message";
        TempBlob_lCdu: Codeunit "Temp Blob";
        Out: OutStream;
        Instr: InStream;
        SO_lRec: Record "Sales Header";
    begin
        //Mail Subject
        Subject := StrSubstNo(Text007, Text50007_gCtx);
        Body := '';
        Body := Text013;
        Body += '<BR/>';
        Body += '<BR/>';

        //Mail Recipient
        UserSetup_lRecVar.Get(ApprovalEntry."Sender ID");
        UserSetup_lRecVar.TestField("E-Mail");
        Recipient := UserSetup_lRecVar."E-Mail";

        //Mail CC
        UserSetup_lRecVar.Get(ApprovalEntry."Approver ID");
        UserSetup_lRecVar.TestField("E-Mail");
        SenderAddress := UserSetup_lRecVar."E-Mail";

        SplitAndAddEmailAddress(EmailReceipent, Recipient);
        SplitAndAddEmailAddress(CC, SenderAddress);

        if SP_lRec.Get(ApprovalEntry."Salespers./Purch. Code") then begin
            if SP_lRec."E-Mail" <> '' then
                SplitAndAddEmailAddress(CC, SP_lRec."E-Mail");
        end;

        EmailMessage_lCdu.Create(EmailReceipent, Subject, '', true, CC, BCC);

        //Email Attachment
        // GetSalesApprovalFilePath_gFnc(SalesHeader."No.", FileName_lTxt);
        // TempBlob_lCdu.CreateOutStream(Out);
        // SalesHeader_lRec.Reset;
        // SalesHeader_lRec.SetRange("Document Type", SalesHeader."Document Type");
        // SalesHeader_lRec.SetRange("No.", SalesHeader."No.");
        // SOPrint_lRpt.SetTableview(SalesHeader_lRec);
        // SOPrint_lRpt.SaveAs('', REPORTFORMAT::Pdf, Out);
        // TempBlob_lCdu.CREATEINSTREAM(Instr);
        // If ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Order then//T43341-N
        // EmailMessage_lCdu.AddAttachment(FileName_lTxt, 'PDF', Instr);

        SO_lRec.RESET;
        SO_lRec.SetRange("Document Type", SalesHeader."Document Type");
        SO_lRec.Setrange("No.", SalesHeader."No.");
        SO_lRec.FINDFIRST;
        Body += 'Sales ' + Format(SalesHeader."Document Type") + ' ' + SalesHeader."No." + ' has been Rejected.';
        Body += '<BR/>';
        Body += '<BR/>';
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Sales Order", SO_lRec, true) + '">' + Text004 + '</a>';
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Sales Invoice", SO_lRec, true) + '">' + Text004 + '</a>';
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Sales Return Order", SO_lRec, true) + '">' + Text004 + '</a>';
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Sales Credit Memo", SO_lRec, true) + '">' + Text004 + '</a>';
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Sales Quote", SO_lRec, true) + '">' + Text004 + '</a>';
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Blanket Order" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Blanket Sales Order", SO_lRec, true) + '">' + Text004 + '</a>';
        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<B>  Sales ' + Format(SalesHeader."Document Type") + ' ' + SalesHeader."No." + '</B>';
        Body += '<BR/>';

        Body += '<table width="100%"><tr><td>';
        Body += '<table cellpadding="0" cellspacing="0" style="border:0.3px solid black;" align="left" width="100%">';

        // TableBodyAppend_gFnc(Body, 'Amount', Format(SalesHeader."Amount To Customer"()));
        // TableBodyAppend_gFnc(Body, 'Amount (LCY)', FOrmat(Round((SalesHeader."Amount To Customer"() / SalesHeader."Currency Factor"), 0.01)));
        TableBodyAppend_gFnc(Body, 'Customer', SalesHeader."Bill-to Customer No." + ' ' + SalesHeader."Bill-to Name");
        TableBodyAppend_gFnc(Body, 'Due  Date', Format(SalesHeader."Due Date"));
        TableBodyAppend_gFnc(Body, 'Creator', ApprovalEntry."Sender ID");
        TableBodyAppend_gFnc(Body, 'Sales/Purchaser Code ', ApprovalEntry."Salespers./Purch. Code");
        TableBodyAppend_gFnc(Body, 'Approver', ApprovalEntry."Approver ID");
        TableBodyAppend_gFnc(Body, 'Comments', GetApprovalCommentLines(ApprovalEntry));

        Body += '</table>';
        EmailMessage_lCdu.AppendToBody(Body);
        Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default);
        // if Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default) then begin
        //     // IsApprovalEntry := false;
        //     // Clear(ApprovalEntry_gRec);
        // end;
    end;

    procedure SendPurchaseRejectedMail_gFnc(PurchaseHeader: Record "Purchase Header"; ApprovalEntry: Record "Approval Entry")
    var
        UserSetup_lRecVar: Record "User Setup";
        // POPrint_lRpt: Report "Purchase Order_GST New";
        PurchHeader_lRec: Record "Purchase Header";
        FileName_lTxt: Text[350];
        SP_lRec: Record "Salesperson/Purchaser";
        EmailMessage_lCdu: Codeunit "Email Message";
        TempBlob_lCdu: Codeunit "Temp Blob";
        Out: OutStream;
        Instr: InStream;
        //PurchaseHeader: Record "Purchase Header";
        PO_lRec: Record "Purchase Header";
        WebURL_lTxt: Text;
        CurrencyFactor_lDec: Decimal;

    begin
        //SetTemplate(ApprovalEntry);
        ApprovalEntry.Reset();
        ApprovalEntry.SetRange("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.FindLast();

        //Mail Subject
        Subject := StrSubstNo(Text007, Text50007_gCtx);

        // Mail Receipent
        UserSetup_lRecVar.Get(ApprovalEntry."Sender ID");
        UserSetup_lRecVar.TestField("E-Mail");
        Recipient := UserSetup_lRecVar."E-Mail";

        //Mail CC
        UserSetup_lRecVar.Get(ApprovalEntry."Approver ID");
        UserSetup_lRecVar.TestField("E-Mail");
        SenderAddress := UserSetup_lRecVar."E-Mail";

        SplitAndAddEmailAddress(EmailReceipent, Recipient);
        SplitAndAddEmailAddress(CC, SenderAddress);

        EmailMessage_lCdu.Create(EmailReceipent, Subject, '', true, CC, BCC);

        //Email attachment
        // GetApprovalFilePath_gFnc(PurchaseHeader."No.", FileName_lTxt);

        // TempBlob_lCdu.CreateOutStream(Out);
        // PurchHeader_lRec.Reset;
        // PurchHeader_lRec.SetRange("Document Type", PurchaseHeader."Document Type");
        // PurchHeader_lRec.SetRange("No.", PurchaseHeader."No.");
        // PurchHeader_lRec.FindFirst();
        // POPrint_lRpt.SetTableview(PurchHeader_lRec);
        // POPrint_lRpt.SetTermsCond_gFnc(true, true);
        // POPrint_lRpt.SaveAs('', REPORTFORMAT::Pdf, Out);
        // TempBlob_lCdu.CREATEINSTREAM(Instr);

        //EmailMessage_lCdu.AddAttachment(FileName_lTxt, 'PDF', Instr);

        Body := '';

        PO_lRec.RESET;
        PO_lRec.Setrange("Document Type", PurchaseHeader."Document Type");
        PO_lRec.Setrange("No.", PurchaseHeader."No.");
        PO_lRec.FINDFIRST;

        Body := Text013;
        Body += '<BR/>';
        Body += '<BR/>';

        Body += 'Purchase ' + Format(PurchaseHeader."Document Type") + ' ' + PurchaseHeader."No." + ' has been rejected.';
        Body += '<BR/>';
        Body += '<BR/>';
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Purchase Order", PO_lRec, true) + '">' + Text004 + '</a>';
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Purchase Invoice", PO_lRec, true) + '">' + Text004 + '</a>';
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Purchase Return Order", PO_lRec, true) + '">' + Text004 + '</a>';
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Purchase Credit Memo", PO_lRec, true) + '">' + Text004 + '</a>';
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Purchase Quote", PO_lRec, true) + '">' + Text004 + '</a>';
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Blanket Order" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Blanket Purchase Order", PO_lRec, true) + '">' + Text004 + '</a>';
        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<B>  Purchase ' + Format(PurchaseHeader."Document Type") + ' ' + PurchaseHeader."No." + '</B>';
        Body += '<BR/>';

        Body += '<table width="100%"><tr><td>';
        Body += '<table cellpadding="0" cellspacing="0" style="border:0.3px solid black;" align="left" width="100%">';

        // TableBodyAppend_gFnc(Body, 'Amount', Format(PurchaseHeader."Amount To Vendor"()));
        // if PurchaseHeader."Currency Factor" = 0 then
        //     CurrencyFactor_lDec := 1
        // else
        //     CurrencyFactor_lDec := PurchaseHeader."Currency Factor";

        // TableBodyAppend_gFnc(Body, 'Amount (LCY)', FOrmat(Round((PurchaseHeader."Amount To Vendor"() / CurrencyFactor_lDec), 0.01)));
        TableBodyAppend_gFnc(Body, 'Vendor', PurchaseHeader."Pay-to Vendor No." + ' ' + PurchaseHeader."Pay-to Name");
        TableBodyAppend_gFnc(Body, 'Due  Date', Format(PurchaseHeader."Due Date"));
        TableBodyAppend_gFnc(Body, 'Creator', ApprovalEntry."Sender ID");
        TableBodyAppend_gFnc(Body, 'Sales/Purchaser Code ', ApprovalEntry."Salespers./Purch. Code");
        TableBodyAppend_gFnc(Body, 'Approver', ApprovalEntry."Approver ID");
        TableBodyAppend_gFnc(Body, 'Comments', GetApprovalCommentLines(ApprovalEntry));

        Body += '</table>';
        EmailMessage_lCdu.AppendToBody(Body);
        Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default)

    end;

    procedure SendTransferRejectedMail_gFnc(TransferHeader: Record "Transfer Header"; ApprovalEntry: Record "Approval Entry")
    var
        UserSetup_lRecVar: Record "User Setup";
        // SOPrint_lRpt: Report "Sales Order Approval Request";
        TransferHeader_lRec: Record "Transfer Header";
        FileName_lTxt: Text[350];
        SP_lRec: Record "Salesperson/Purchaser";
        EmailMessage_lCdu: Codeunit "Email Message";
        TempBlob_lCdu: Codeunit "Temp Blob";
        Out: OutStream;
        Instr: InStream;
        TO_lRec: Record "Transfer Header";
    begin
        //Mail Subject
        Subject := StrSubstNo(Text007, Text50007_gCtx);
        Body := '';
        Body := Text013;
        Body += '<BR/>';
        Body += '<BR/>';

        //Mail Recipient
        UserSetup_lRecVar.Get(ApprovalEntry."Sender ID");
        UserSetup_lRecVar.TestField("E-Mail");
        Recipient := UserSetup_lRecVar."E-Mail";

        //Mail CC
        UserSetup_lRecVar.Get(ApprovalEntry."Approver ID");
        UserSetup_lRecVar.TestField("E-Mail");
        SenderAddress := UserSetup_lRecVar."E-Mail";

        SplitAndAddEmailAddress(EmailReceipent, Recipient);
        SplitAndAddEmailAddress(CC, SenderAddress);

        if SP_lRec.Get(ApprovalEntry."Salespers./Purch. Code") then begin
            if SP_lRec."E-Mail" <> '' then
                SplitAndAddEmailAddress(CC, SP_lRec."E-Mail");
        end;

        EmailMessage_lCdu.Create(EmailReceipent, Subject, '', true, CC, BCC);

        //Email Attachment
        // GetSalesApprovalFilePath_gFnc(SalesHeader."No.", FileName_lTxt);
        // TempBlob_lCdu.CreateOutStream(Out);
        // SalesHeader_lRec.Reset;
        // SalesHeader_lRec.SetRange("Document Type", SalesHeader."Document Type");
        // SalesHeader_lRec.SetRange("No.", SalesHeader."No.");
        // SOPrint_lRpt.SetTableview(SalesHeader_lRec);
        // SOPrint_lRpt.SaveAs('', REPORTFORMAT::Pdf, Out);
        // TempBlob_lCdu.CREATEINSTREAM(Instr);
        // If ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Order then//T43341-N
        // EmailMessage_lCdu.AddAttachment(FileName_lTxt, 'PDF', Instr);

        TO_lRec.RESET;
        TO_lRec.Setrange("No.", TransferHeader."No.");
        TO_lRec.FINDFIRST;
        Body += 'Transfer Order ' + TransferHeader."No." + ' has been Rejected.';
        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Transfer Order", TO_lRec, true) + '">' + Text004 + '</a>';

        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<B>  Transfer Order ' + TransferHeader."No." + '</B>';
        Body += '<BR/>';

        Body += '<table width="100%"><tr><td>';
        Body += '<table cellpadding="0" cellspacing="0" style="border:0.3px solid black;" align="left" width="100%">';

        // TableBodyAppend_gFnc(Body, 'Amount', Format(TransferHeader."Amount To Customer"()));
        // TableBodyAppend_gFnc(Body, 'Amount (LCY)', FOrmat(Round((TransferHeader."Amount To Customer"() / TransferHeader."Currency Factor"), 0.01)));
        // TableBodyAppend_gFnc(Body, 'Customer', SalesHeader."Bill-to Customer No." + ' ' + SalesHeader."Bill-to Name");
        // TableBodyAppend_gFnc(Body, 'Due  Date', Format(SalesHeader."Due Date"));
        TableBodyAppend_gFnc(Body, 'Creator', ApprovalEntry."Sender ID");
        // TableBodyAppend_gFnc(Body, 'Sales/Purchaser Code ', ApprovalEntry."Salespers./Purch. Code");
        TableBodyAppend_gFnc(Body, 'Approver', ApprovalEntry."Approver ID");
        TableBodyAppend_gFnc(Body, 'Comments', GetApprovalCommentLines(ApprovalEntry));

        Body += '</table>';
        EmailMessage_lCdu.AppendToBody(Body);
        Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default);

    end;

    procedure SendServiceRejectMail_gFnc(ServiceHeader: Record "Service Header"; ApprovalEntry: Record "Approval Entry")
    var
        UserSetup_lRecVar: Record "User Setup";
        // POPrint_lRpt: Report "Purchase Order_GST New";
        ServiceHeader_lRec: Record "Service Header";
        FileName_lTxt: Text[350];
        SP_lRec: Record "Salesperson/Purchaser";
        EmailMessage_lCdu: Codeunit "Email Message";
        Cus_lRec: Record Customer;
        TempBlob_lCdu: Codeunit "Temp Blob";
        Out: OutStream;
        Instr: InStream;
        SerO_lRec: Record "Service Header";
        WebURL_lTxt: Text;
        CurrencyFactor_lDec: Decimal;

    begin
        //SetTemplate(ApprovalEntry);
        ApprovalEntry.Reset();
        ApprovalEntry.SetRange("Record ID to Approve", ServiceHeader.RecordId);
        ApprovalEntry.FindLast();

        //Mail Subject
        Subject := StrSubstNo(Text007, Text50007_gCtx);

        // Mail Receipent
        UserSetup_lRecVar.Get(ApprovalEntry."Sender ID");
        UserSetup_lRecVar.TestField("E-Mail");
        Recipient := UserSetup_lRecVar."E-Mail";

        //Mail CC
        UserSetup_lRecVar.Get(ApprovalEntry."Approver ID");
        UserSetup_lRecVar.TestField("E-Mail");
        SenderAddress := UserSetup_lRecVar."E-Mail";

        SplitAndAddEmailAddress(EmailReceipent, Recipient);
        SplitAndAddEmailAddress(CC, SenderAddress);

        if SP_lRec.Get(ApprovalEntry."Salespers./Purch. Code") then begin
            if SP_lRec."E-Mail" <> '' then
                SplitAndAddEmailAddress(CC, SP_lRec."E-Mail");
        end;

        EmailMessage_lCdu.Create(EmailReceipent, Subject, '', true, CC, BCC);

        //Email attachment
        // GetApprovalFilePath_gFnc(PurchaseHeader."No.", FileName_lTxt);

        // TempBlob_lCdu.CreateOutStream(Out);
        // PurchHeader_lRec.Reset;
        // PurchHeader_lRec.SetRange("Document Type", PurchaseHeader."Document Type");
        // PurchHeader_lRec.SetRange("No.", PurchaseHeader."No.");
        // PurchHeader_lRec.FindFirst();
        // POPrint_lRpt.SetTableview(PurchHeader_lRec);
        // POPrint_lRpt.SetTermsCond_gFnc(true, true);
        // POPrint_lRpt.SaveAs('', REPORTFORMAT::Pdf, Out);
        // TempBlob_lCdu.CREATEINSTREAM(Instr);

        //EmailMessage_lCdu.AddAttachment(FileName_lTxt, 'PDF', Instr);

        Body := '';

        SerO_lRec.RESET;
        SerO_lRec.SetRange("Document Type", ServiceHeader."Document Type");
        SerO_lRec.Setrange("No.", ServiceHeader."No.");
        SerO_lRec.FINDFIRST;

        Body := Text013;
        Body += '<BR/>';
        Body += '<BR/>';

        Body += 'Service  ' + Format(ServiceHeader."Document Type") + ' ' + ServiceHeader."No." + ' has been Rejected.';
        Body += '<BR/>';
        Body += '<BR/>';
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Order then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Service Order", SerO_lRec, true) + '">' + Text004 + '</a>';
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Service Invoice", SerO_lRec, true) + '">' + Text004 + '</a>';
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Service Credit Memo", SerO_lRec, true) + '">' + Text004 + '</a>';
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Quote then
            Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Service Quote", SerO_lRec, true) + '">' + Text004 + '</a>';

        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<B>  Service  ' + Format(ServiceHeader."Document Type") + ' ' + ServiceHeader."No." + '</B>';
        Body += '<BR/>';

        Body += '<table width="100%"><tr><td>';
        Body += '<table cellpadding="0" cellspacing="0" style="border:0.3px solid black;" align="left" width="100%">';

        // TableBodyAppend_gFnc(Body, 'Amount', Format(PurchaseHeader."Amount To Vendor"()));
        // if PurchaseHeader."Currency Factor" = 0 then
        //     CurrencyFactor_lDec := 1
        // else
        //     CurrencyFactor_lDec := PurchaseHeader."Currency Factor";

        // TableBodyAppend_gFnc(Body, 'Amount (LCY)', FOrmat(Round((PurchaseHeader."Amount To Vendor"() / CurrencyFactor_lDec), 0.01)));
        Cus_lRec.get(ServiceHeader."Customer No.");
        TableBodyAppend_gFnc(Body, 'Customer', ServiceHeader."Customer No." + ' ' + Cus_lRec.Name);
        TableBodyAppend_gFnc(Body, 'Due  Date', Format(ServiceHeader."Due Date"));
        TableBodyAppend_gFnc(Body, 'Creator', ApprovalEntry."Sender ID");
        TableBodyAppend_gFnc(Body, 'Sales/Purchaser Code ', ApprovalEntry."Salespers./Purch. Code");
        TableBodyAppend_gFnc(Body, 'Approver', ApprovalEntry."Approver ID");
        TableBodyAppend_gFnc(Body, 'Comments', GetApprovalCommentLines(ApprovalEntry));

        Body += '</table>';
        EmailMessage_lCdu.AppendToBody(Body);
        Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default)

    end;

    procedure TableBodyAppend_gFnc(var Body_vTxt: Text; Caption_iTxt: Text; Value_iTxt: Text)
    begin
        Body_vTxt += '<tr><td align="left" Style="border:0.3px solid Black; font-weight:bold;padding:0px 5px 0px 5px;background-color: #DEF3F9"  Width="30%">' + Caption_iTxt + '</td>';
        Body_vTxt += '<td Style="border:0.3px solid Black;padding:0px 5px 0px 5px" align="left" Width="70%">' + Value_iTxt + '</td></tr>';
    end;

    procedure SplitAndAddEmailAddress(var Recipients_vtxt: List of [Text]; InputAddress_iTxt: Text)
    var
        LastChr: Text;
        TmpRecipients: Text;
    begin

        IF InputAddress_iTxt = '' then
            Exit;

        InputAddress_iTxt := DELCHR(InputAddress_iTxt, '<>', ' ');

        IF STRPOS(InputAddress_iTxt, ';') <> 0 THEN BEGIN  //System doesn't work if the email address end with semi colon  /ex: nileshg@intech-systems.com;
            LastChr := COPYSTR(InputAddress_iTxt, STRLEN(InputAddress_iTxt));
            IF LastChr = ';' THEN
                InputAddress_iTxt := COPYSTR(InputAddress_iTxt, 1, STRPOS(InputAddress_iTxt, ';') - 1);
        END;

        IF STRPOS(InputAddress_iTxt, ',') <> 0 THEN BEGIN  //System doesn't work if the email address end with Comma  /ex: nileshg@intech-systems.com,
            LastChr := COPYSTR(InputAddress_iTxt, STRLEN(InputAddress_iTxt));
            IF LastChr = ',' THEN
                InputAddress_iTxt := COPYSTR(InputAddress_iTxt, 1, STRPOS(InputAddress_iTxt, ',') - 1);
        END;

        TmpRecipients := DELCHR(InputAddress_iTxt, '<>', ';');
        WHILE STRPOS(TmpRecipients, ';') > 1 DO BEGIN
            Recipients_vtxt.Add((COPYSTR(TmpRecipients, 1, STRPOS(TmpRecipients, ';') - 1)));
            TmpRecipients := COPYSTR(TmpRecipients, STRPOS(TmpRecipients, ';') + 1);
        END;

        IF TmpRecipients <> '' Then
            Recipients_vtxt.Add(TmpRecipients);
    end;

    local procedure GetApprovalCommentLines(ApprovalEntry: Record "Approval Entry") HTMLApprovalComments: Text
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalEntry.CalcFields(Comment);
        if not ApprovalEntry.Comment then
            exit;

        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        if ApprovalCommentLine.FindSet then begin
            repeat
                HTMLApprovalComments += StrSubstNo(AdditionalHtmlLineTxt, ApprovalCommentLine.Comment);
            until ApprovalCommentLine.Next = 0;
        end;
    end;


    var
        IsApprovalEntry: Boolean;
        ApprovalEntry_gRec: Record "Approval Entry";
        Usersetup_gRec: Record "User Setup";
        EmailReceipent: List of [Text];
        CC: List of [Text];
        BCC: List of [Text];
        Email: Codeunit Email;
        SMTP: Codeunit "Email Message";
        SenderName: Text[100];
        SenderAddress: Text[100];
        Recipient: Text[100];
        Subject: Text[100];
        Body: Text;
        AdditionalHtmlLineTxt: label '<p><span style="font-size: 11.0pt; font-family: Calibri">%1</span></p>', Locked = true;
        Text004: label 'To view your Rejected document, please use this link (Web Link)';
        Text50007_gCtx: label 'Rejected';
        Text013: label 'Microsoft Dynamics Business Central Document Approval System';
        Text007: label 'Microsoft Dynamics Business Central: %1 Mail';
}