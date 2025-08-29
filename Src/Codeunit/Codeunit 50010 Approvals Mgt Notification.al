Codeunit 80931 "Approvals Mgt Notification"
{
    Permissions = TableData "Overdue Approval Entry" = i;

    trigger OnRun()
    begin
    end;

    var
        Text001: label 'Sales %1';
        Text002: label 'Purchase %1';
        Text003: label 'requires your approval.';
        Text004: label 'To view your approved document, please use this link (Web Link)';
        Text005: label 'Customer';
        WebViewTok: label 'Web view', Comment = 'Opens the document in the Microsoft Dynamics Business Central web client';
        Text007: label 'Microsoft Dynamics Business Central: %1 Mail';
        Text008: label 'Approval';
        Text009: label 'Cancellation';
        Text010: label 'Rejection';
        Text011: label 'Delegation';
        Text012: label 'Overdue Approvals';
        Text013: label 'Microsoft Dynamics Business Central Document Approval System';
        Text014: label 'has been cancelled.';
        Text016: label 'has been rejected.';
        Text018: label 'Vendor';
        Text020: label 'has been delegated.';
        Text022: label 'Overdue approval';
        Text030: label 'Not yet overdue';
        Text033: label 'Rejection comments:';
        Text040: label 'You must import an Approval Template in Approval Setup.';
        Text041: label 'You must import an Overdue Approval Template in Approval Setup.';
        Text042: label 'Available Credit Limit (LCY)';
        Text043: label 'Request Amount (LCY)';
        OpenBracketTok: label '(', Locked = true;
        CloseBracketTok: label ')', Locked = true;
        Text50007_gCtx: label 'Approved';
        Text50008_gCtx: label 'has been approved.';
        Text50009_gCtx: label 'Approved By :';
        SMTP: Codeunit "Email Message";
        SenderName: Text[100];
        SenderAddress: Text[100];
        Recipient: Text[100];
        Subject: Text[100];
        Body: Text;
        InStreamTemplate: InStream;
        InSReadChar: Text[1];
        CharNo: Text[4];
        I: Integer;
        MailCreated: Boolean;
        EmailReceipent: List of [Text];
        CC: List of [Text];
        BCC: List of [Text];
        Email: Codeunit Email;


        AdditionalHtmlLineTxt: label '<p><span style="font-size: 11.0pt; font-family: Calibri">%1</span></p>', Locked = true;


    procedure FillPurchaseTemplate(var Body: Text; FieldNo: Text[30]; Header: Record "Purchase Header"; AppEntry: Record "Approval Entry"; CalledFrom: Option Approve,Cancel,Reject,Delegate,Approved)
    begin
        case FieldNo of
            '1':
                Body := StrSubstNo(Text002, Header."Document Type");
            '2':
                Body := StrSubstNo(Body, Header."No.");
            '3':
                case CalledFrom of
                    Calledfrom::Approve:
                        Body := StrSubstNo(Body, Text003);
                    Calledfrom::Cancel:
                        Body := StrSubstNo(Body, Text014);
                    Calledfrom::Reject:
                        Body := StrSubstNo(Body, Text016);
                    Calledfrom::Delegate:
                        Body := StrSubstNo(Body, Text020);
                    //I-I035-400026-01-NS
                    Calledfrom::Approved:
                        Body := StrSubstNo(Body, Text50008_gCtx);
                //I-I035-400026-01-NE
                end;
            '4':
                if CalledFrom in [Calledfrom::Approve, Calledfrom::Cancel, Calledfrom::Reject, Calledfrom::Delegate, Calledfrom::Approved] then
                    Body := '';
            '5':
                Body := StrSubstNo(Body, GetApprovalEntriesWinUri);
            '6':
                Body := StrSubstNo(Body, Text004);
            '7':
                Body := StrSubstNo(Body, AppEntry.FieldCaption(Amount));
            '8':
                Body := StrSubstNo(Body, AppEntry."Currency Code");
            '9':
                Body := StrSubstNo(Body, AppEntry.Amount);
            '10':
                Body := StrSubstNo(Body, AppEntry.FieldCaption("Amount (LCY)"));
            '11':
                Body := StrSubstNo(Body, AppEntry."Amount (LCY)");
            '12':
                Body := StrSubstNo(Body, Text018);
            '13':
                Body := StrSubstNo(Body, Header."Pay-to Vendor No.");
            '14':
                Body := StrSubstNo(Body, Header."Pay-to Name");
            '15':
                Body := StrSubstNo(Body, AppEntry.FieldCaption("Due Date"));
            '16':
                Body := StrSubstNo(Body, AppEntry."Due Date");
            '17':
                begin
                    if AppEntry."Limit Type" = AppEntry."limit type"::"Request Limits" then
                        Body := Text043
                    else
                        Body := ' ';
                end;
            '18':
                begin
                    if AppEntry."Limit Type" = AppEntry."limit type"::"Request Limits" then
                        Body := StrSubstNo(Body, AppEntry."Amount (LCY)")
                    else
                        Body := ' ';
                end;
            '19':
                Body := StrSubstNo(Body, GetApprovalEntriesWebUri);
            '20':
                Body := StrSubstNo(Body, WebViewTok);
            '21':
                Body := StrSubstNo(Body, OpenBracketTok);
            '22':
                Body := StrSubstNo(Body, CloseBracketTok);

            //T6140-NS
            '23':
                Body := 'Creator';
            '24':
                Body := AppEntry."Sender ID";
            '25':
                Body := 'Sales/Purchaser Code ';
            '26':
                Body := AppEntry."Salespers./Purch. Code";
            '27':
                Body := 'Approver';
            '28':
                Body := AppEntry."Approver ID";
            '29':
                Body := 'Comments';
            '30':
                Body := GetApprovalCommentLines(AppEntry);
        //T6140-NE
        end;
    end;

    local procedure GetApprovalEntriesWinUri(): Text
    begin
        // Generates a url to the Approval Entries list page, such as
        // dynamicsnav://server:port/instance/company/runpage?page=658<?Tenant=tenantId>.
        exit(GetUrl(Clienttype::Windows, COMPANYNAME, Objecttype::Page, Page::"Requests to Approve"));
    end;

    local procedure GetApprovalEntriesWebUri(): Text
    begin
        // Generates a url to the Approval Entries list page, such as
        // http://server:port/instance/WebClient/company/runpage?page=658<?Tenant=tenantId>.
        exit(GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Requests to Approve"));
    end;


    procedure SetTemplate(AppEntry: Record "Approval Entry")
    var
    // AppSetup: Record "Approval Setup";
    begin
        // AppSetup.GET;
        // AppSetup.CALCFIELDS("Approval Template");
        // IF NOT AppSetup."Approval Template".HASVALUE THEN
        //     ERROR(Text040);
        // AppSetup."Approval Template".CREATEINSTREAM(InStreamTemplate);
        SenderName := COMPANYNAME;
        CLEAR(SenderAddress);
        CLEAR(Recipient);
        GetEmailAddress(AppEntry);
    end;


    procedure GetEmailAddress(AppEntry: Record "Approval Entry")
    var
        UserSetup_lRec: Record "User Setup";
        SalesHeader_lRec: Record "Sales Header";
        PurchaseHeader_lRec: Record "Purchase Header";
        DocSubType_lCod: Code[10];
    begin
        // if AppEntry."Table ID" = 36 then
        //     if SalesHeader_lRec.Get(AppEntry."Document Type", AppEntry."Document No.") then
        //         DocSubType_lCod := SalesHeader_lRec."Approval Criteria";

        // if AppEntry."Table ID" = 38 then
        //     if PurchaseHeader_lRec.Get(AppEntry."Document Type", AppEntry."Document No.") then
        //         DocSubType_lCod := PurchaseHeader_lRec."Approval Criteria";

        UserSetup_lRec.Get(AppEntry."Sender ID");
        UserSetup_lRec.TestField("E-Mail");
        SenderAddress := UserSetup_lRec."E-Mail";

        UserSetup_lRec.Get(AppEntry."Approver ID");
        UserSetup_lRec.TestField("E-Mail");
        Recipient := UserSetup_lRec."E-Mail";
    end;


    procedure SendPurchaseApprovedMail_gFnc(PurchaseHeader: Record "Purchase Header"; ApprovalEntry: Record "Approval Entry")
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

        Body += 'Purchase ' + Format(PurchaseHeader."Document Type") + ' ' + PurchaseHeader."No." + ' has been approved.';
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

    procedure SendSalesApprovedMail_gFnc(SalesHeader: Record "Sales Header"; ApprovalEntry: Record "Approval Entry")
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
        Body += 'Sales ' + Format(SalesHeader."Document Type") + ' ' + SalesHeader."No." + ' has been approved.';
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

    end;

    procedure SendTransferApprovedMail_gFnc(TransferHeader: Record "Transfer Header"; ApprovalEntry: Record "Approval Entry")
    var
        UserSetup_lRecVar: Record "User Setup";
        // POPrint_lRpt: Report "Purchase Order_GST New";
        TransHeader_lRec: Record "Transfer Header";
        FileName_lTxt: Text[350];
        SP_lRec: Record "Salesperson/Purchaser";
        EmailMessage_lCdu: Codeunit "Email Message";
        TempBlob_lCdu: Codeunit "Temp Blob";
        Out: OutStream;
        Instr: InStream;
        TO_lRec: Record "Transfer Header";
        WebURL_lTxt: Text;
        CurrencyFactor_lDec: Decimal;

    begin
        //SetTemplate(ApprovalEntry);
        ApprovalEntry.Reset();
        ApprovalEntry.SetRange("Record ID to Approve", TransferHeader.RecordId);
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

        TO_lRec.RESET;
        TO_lRec.Setrange("No.", TransferHeader."No.");
        TO_lRec.FINDFIRST;

        Body := Text013;
        Body += '<BR/>';
        Body += '<BR/>';

        Body += 'Transfer Order ' + TransferHeader."No." + ' has been approved.';
        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Transfer Order", TO_lRec, true) + '">' + Text004 + '</a>';

        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<B>  Transfer Order ' + TransferHeader."No." + '</B>';
        Body += '<BR/>';

        Body += '<table width="100%"><tr><td>';
        Body += '<table cellpadding="0" cellspacing="0" style="border:0.3px solid black;" align="left" width="100%">';

        // TableBodyAppend_gFnc(Body, 'Amount', Format(PurchaseHeader."Amount To Vendor"()));
        // if PurchaseHeader."Currency Factor" = 0 then
        //     CurrencyFactor_lDec := 1
        // else
        //     CurrencyFactor_lDec := PurchaseHeader."Currency Factor";

        // TableBodyAppend_gFnc(Body, 'Amount (LCY)', FOrmat(Round((PurchaseHeader."Amount To Vendor"() / CurrencyFactor_lDec), 0.01)));
        // TableBodyAppend_gFnc(Body, 'Vendor', TransferHeader."Pay-to Vendor No." + ' ' + PurchaseHeader."Pay-to Name");
        // TableBodyAppend_gFnc(Body, 'Due  Date', Format(TransferHeader."Due Date"));
        TableBodyAppend_gFnc(Body, 'Creator', ApprovalEntry."Sender ID");
        // TableBodyAppend_gFnc(Body, 'Sales/Purchaser Code ', ApprovalEntry."Salespers./Purch. Code");
        TableBodyAppend_gFnc(Body, 'Approver', ApprovalEntry."Approver ID");
        TableBodyAppend_gFnc(Body, 'Comments', GetApprovalCommentLines(ApprovalEntry));

        Body += '</table>';
        EmailMessage_lCdu.AppendToBody(Body);
        Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default)

    end;

    procedure SendProductionApprovedMail_gFnc(ProductionOrder: Record "Production Order"; ApprovalEntry: Record "Approval Entry")
    var
        UserSetup_lRecVar: Record "User Setup";
        // POPrint_lRpt: Report "Purchase Order_GST New";
        ProductionOrder_lRec: Record "Production Order";
        FileName_lTxt: Text[350];
        SP_lRec: Record "Salesperson/Purchaser";
        EmailMessage_lCdu: Codeunit "Email Message";
        TempBlob_lCdu: Codeunit "Temp Blob";
        Out: OutStream;
        Instr: InStream;
        PO_lRec: Record "Production Order";
        WebURL_lTxt: Text;
        CurrencyFactor_lDec: Decimal;

    begin
        //SetTemplate(ApprovalEntry);
        ApprovalEntry.Reset();
        ApprovalEntry.SetRange("Record ID to Approve", ProductionOrder.RecordId);
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
        PO_lRec.Setrange("No.", ProductionOrder."No.");
        PO_lRec.FINDFIRST;

        Body := Text013;
        Body += '<BR/>';
        Body += '<BR/>';

        Body += 'Production Order ' + ProductionOrder."No." + ' has been approved.';
        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<a href="' + GetUrl(Clienttype::Web, COMPANYNAME, Objecttype::Page, Page::"Firm Planned Prod. Order", PO_lRec, true) + '">' + Text004 + '</a>';

        Body += '<BR/>';
        Body += '<BR/>';
        Body += '<B>  Production Order ' + ProductionOrder."No." + '</B>';
        Body += '<BR/>';

        Body += '<table width="100%"><tr><td>';
        Body += '<table cellpadding="0" cellspacing="0" style="border:0.3px solid black;" align="left" width="100%">';

        // TableBodyAppend_gFnc(Body, 'Amount', Format(PurchaseHeader."Amount To Vendor"()));
        // if PurchaseHeader."Currency Factor" = 0 then
        //     CurrencyFactor_lDec := 1
        // else
        //     CurrencyFactor_lDec := PurchaseHeader."Currency Factor";

        // TableBodyAppend_gFnc(Body, 'Amount (LCY)', FOrmat(Round((PurchaseHeader."Amount To Vendor"() / CurrencyFactor_lDec), 0.01)));
        // TableBodyAppend_gFnc(Body, 'Vendor', ProductionOrder."Pay-to Vendor No." + ' ' + PurchaseHeader."Pay-to Name");
        // TableBodyAppend_gFnc(Body, 'Due  Date', Format(ProductionOrder."Due Date"));
        TableBodyAppend_gFnc(Body, 'Creator', ApprovalEntry."Sender ID");
        // TableBodyAppend_gFnc(Body, 'Sales/Purchaser Code ', ApprovalEntry."Salespers./Purch. Code");
        TableBodyAppend_gFnc(Body, 'Approver', ApprovalEntry."Approver ID");
        TableBodyAppend_gFnc(Body, 'Comments', GetApprovalCommentLines(ApprovalEntry));

        Body += '</table>';
        EmailMessage_lCdu.AppendToBody(Body);
        Email.Send(EmailMessage_lCdu, Enum::"Email Scenario"::Default)

    end;


    procedure SendServiceApprovedMail_gFnc(ServiceHeader: Record "Service Header"; ApprovalEntry: Record "Approval Entry")
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

        Body += 'Service  ' + Format(ServiceHeader."Document Type") + ' ' + ServiceHeader."No." + ' has been approved.';
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

    procedure GetApprovalFilePath_gFnc(PurchOrderNo_iCod: Code[20]; var FileName_vTxt: Text[350])
    var
        PurchSetUp_lRec: Record "Purchases & Payables Setup";
        PurchOrderNo_lCod: Code[20];
        Name_lTxt: Text[100];
        Text50000_lCtx: label 'Purchase Order No. %1.pdf';
    begin
        //I-I035-400026-01-NS
        FileName_vTxt := '';
        Name_lTxt := '';
        PurchOrderNo_lCod := '';
        PurchSetUp_lRec.Get;
        // PurchSetUp_lRec.TestField("File Path for PO");
        PurchOrderNo_lCod := DelChr(PurchOrderNo_iCod, '=', '/');
        Name_lTxt := StrSubstNo(Text50000_lCtx, PurchOrderNo_lCod);
        FileName_vTxt := Name_lTxt;
        //I-I035-400026-01-NE
    end;

    procedure GetSalesApprovalFilePath_gFnc(SalesOrderNo_iCod: Code[20]; var FileName_vTxt: Text[350])
    var
        SalesReceivablesSetup_lRec: Record "Sales & Receivables Setup";
        SalesOrderNo_lCod: Code[20];
        Name_lTxt: Text[100];
        Text50000_lCtx: label 'Sales Order No %1.pdf';
    begin
        //I-I035-400026-01-NS
        FileName_vTxt := '';
        Name_lTxt := '';
        SalesOrderNo_lCod := '';
        SalesReceivablesSetup_lRec.Get;
        // SalesReceivablesSetup_lRec.TestField("File Path for SO");
        SalesOrderNo_lCod := DelChr(SalesOrderNo_iCod, '=', '/');
        Name_lTxt := StrSubstNo(Text50000_lCtx, SalesOrderNo_lCod);
        FileName_vTxt := Name_lTxt;
        //I-I035-400026-01-NE
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

    procedure FillSalesTemplate(var Body: Text; FieldNo: Text[30]; Header: Record "Sales Header"; AppEntry: Record "Approval Entry"; CalledFrom: Option Approve,Cancel,Reject,Delegate,Approved)
    begin
        case FieldNo of
            '1':
                Body := StrSubstNo(Text001, Header."Document Type");
            '2':
                Body := StrSubstNo(Body, Header."No.");
            '3':
                case CalledFrom of
                    Calledfrom::Approve:
                        Body := StrSubstNo(Body, Text003);
                    Calledfrom::Cancel:
                        Body := StrSubstNo(Body, Text014);
                    Calledfrom::Reject:
                        Body := StrSubstNo(Body, Text016);
                    Calledfrom::Delegate:
                        Body := StrSubstNo(Body, Text020);
                    //T6140-NS
                    Calledfrom::Approved:
                        Body := StrSubstNo(Body, Text50008_gCtx);
                //T6140-NE
                end;
            '4':
                if CalledFrom in [Calledfrom::Approve, Calledfrom::Cancel, Calledfrom::Reject, Calledfrom::Delegate, Calledfrom::Approved] then
                    Body := '';
            '5':
                Body := StrSubstNo(Body, GetApprovalEntriesWinUri);
            '6':
                Body := StrSubstNo(Body, Text004);
            '7':
                Body := StrSubstNo(Body, AppEntry.FieldCaption(Amount));
            '8':
                Body := StrSubstNo(Body, AppEntry."Currency Code");
            '9':
                Body := StrSubstNo(Body, AppEntry.Amount);
            '10':
                Body := StrSubstNo(Body, AppEntry.FieldCaption("Amount (LCY)"));
            '11':
                Body := StrSubstNo(Body, AppEntry."Amount (LCY)");
            '12':
                Body := StrSubstNo(Body, Text005);
            '13':
                Body := StrSubstNo(Body, Header."Bill-to Customer No.");
            '14':
                Body := StrSubstNo(Body, Header."Bill-to Name");
            '15':
                Body := StrSubstNo(Body, AppEntry.FieldCaption("Due Date"));
            //  '16': //T26069-O
            //    Body := STRSUBSTNO(Body,AppEntry."Due Date"); //T26069-O
            '16':
                Body := StrSubstNo(Body, Header."Due Date"); //T26069-N
            '17':
                Body := Text042;
            '18':
                Body := StrSubstNo(Body, AppEntry."Available Credit Limit (LCY)");
            '19':
                Body := StrSubstNo(Body, GetApprovalEntriesWebUri);
            '20':
                Body := StrSubstNo(Body, WebViewTok);
            '21':
                Body := StrSubstNo(Body, OpenBracketTok);
            '22':
                Body := StrSubstNo(Body, CloseBracketTok);

            //T6140-NS
            '23':
                Body := 'Creator';
            '24':
                Body := AppEntry."Sender ID";
            '25':
                Body := 'Sales/Purchaser Code ';
            '26':
                Body := AppEntry."Salespers./Purch. Code";
            '27':
                Body := 'Approver';
            '28':
                Body := AppEntry."Approver ID";
            '29':
                Body := 'Comments';
            '30':
                Body := GetApprovalCommentLines(AppEntry);
        //T6140-NE
        end;
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
}

